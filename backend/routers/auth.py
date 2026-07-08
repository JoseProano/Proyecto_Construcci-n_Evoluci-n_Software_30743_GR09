"""
AmazonFish – Router: Autenticación
Login con JWT, consulta de usuario autenticado.
"""
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from database import get_db
from models import Usuario, UsuarioRol, Rol, Persona
from schemas import (
    LoginRequest, TokenResponse, UsuarioConRolesResponse, UsuarioRolResponse, RolResponse,
    PublicRegisterRequest, PasswordRecoveryRequest,
)
from security import verify_password, create_access_token, get_current_user, get_password_hash

router = APIRouter()


@router.post("/login", response_model=TokenResponse)
def login(request: LoginRequest, db: Session = Depends(get_db)):
    """Autentica al usuario y retorna un token JWT con sus roles."""
    usuario = db.query(Usuario).filter(
        Usuario.username == request.username,
        Usuario.estado == True,
    ).first()

    if not usuario or not verify_password(request.password, usuario.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Credenciales incorrectas. Verifique su usuario y contraseña.",
        )

    # Obtener roles activos del usuario
    asignaciones = db.query(UsuarioRol).filter(
        UsuarioRol.id_usuario == usuario.id_usuario,
        UsuarioRol.estado == True,
    ).all()
    nombres_roles = [a.rol.nombre for a in asignaciones if a.rol]

    # Actualizar último acceso
    usuario.ultimo_acceso = datetime.utcnow()
    db.commit()

    # Crear JWT con roles embebidos
    token = create_access_token(data={
        "sub": str(usuario.id_usuario),
        "username": usuario.username,
        "roles": nombres_roles,
    })

    # Construir respuesta con roles
    roles_resp = [
        UsuarioRolResponse(
            id_usuario_rol=a.id_usuario_rol,
            id_usuario=a.id_usuario,
            id_rol=a.id_rol,
            fecha_asignacion=a.fecha_asignacion,
            estado=a.estado,
            rol=RolResponse(
                id_rol=a.rol.id_rol,
                nombre=a.rol.nombre,
                descripcion=a.rol.descripcion,
                estado=a.rol.estado,
                fecha_creacion=a.rol.fecha_creacion,
            ) if a.rol else None,
        )
        for a in asignaciones
    ]

    usuario_resp = UsuarioConRolesResponse(
        id_usuario=usuario.id_usuario,
        id_persona=usuario.id_persona,
        username=usuario.username,
        estado=usuario.estado,
        fecha_creacion=usuario.fecha_creacion,
        roles=roles_resp,
    )

    return TokenResponse(access_token=token, usuario=usuario_resp)


@router.get("/me")
def get_me(current_user: dict = Depends(get_current_user)):
    """Retorna la información del usuario autenticado (payload del JWT)."""
    return current_user


@router.post("/register", status_code=status.HTTP_201_CREATED)
def register(request: PublicRegisterRequest, db: Session = Depends(get_db)):
    """Registra una nueva persona y su usuario asociado con rol 'socio' por defecto."""
    # Verificar si ya existe persona con la misma identificación o correo
    existing_persona = db.query(Persona).filter(
        (Persona.identificacion == request.identificacion) | (Persona.correo == request.correo)
    ).first()
    if existing_persona:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ya existe una persona registrada con esta identificación o correo.",
        )

    # Verificar si el username está en uso
    existing_user = db.query(Usuario).filter(Usuario.username == request.username).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El nombre de usuario ya está en uso.",
        )

    # Crear Persona
    nueva_persona = Persona(
        nombres=request.nombres,
        apellidos=request.apellidos,
        identificacion=request.identificacion,
        correo=request.correo,
        telefono=request.telefono,
    )
    db.add(nueva_persona)
    db.flush()  # Para obtener id_persona

    # Crear Usuario
    nuevo_usuario = Usuario(
        id_persona=nueva_persona.id_persona,
        username=request.username,
        password_hash=get_password_hash(request.password),
    )
    db.add(nuevo_usuario)
    db.flush()  # Para obtener id_usuario

    # Asignar Rol 'socio'
    rol_socio = db.query(Rol).filter(Rol.nombre == "socio").first()
    if not rol_socio:
        rol_socio = Rol(nombre="socio", descripcion="Cliente/Socio del negocio acuícola")
        db.add(rol_socio)
        db.flush()

    asignacion = UsuarioRol(
        id_usuario=nuevo_usuario.id_usuario,
        id_rol=rol_socio.id_rol,
    )
    db.add(asignacion)
    db.commit()

    return {"message": "Registro completado con éxito.", "username": request.username}


@router.post("/recover-password")
def recover_password(request: PasswordRecoveryRequest, db: Session = Depends(get_db)):
    """Simula recuperación de contraseña verificando datos e ingresando la nueva clave."""
    usuario = db.query(Usuario).filter(Usuario.username == request.username).first()
    if not usuario:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Nombre de usuario no encontrado.",
        )

    persona = usuario.persona
    if not persona or persona.identificacion != request.identificacion or persona.correo != request.correo:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Los datos proporcionados no coinciden con nuestros registros.",
        )

    # Cambiar contraseña
    usuario.password_hash = get_password_hash(request.new_password)
    db.commit()

    return {"message": "Contraseña restablecida correctamente."}

