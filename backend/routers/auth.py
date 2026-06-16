"""
AmazonFish – Router: Autenticación
Login con JWT, consulta de usuario autenticado.
"""
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from database import get_db
from models import Usuario, UsuarioRol, Rol
from schemas import LoginRequest, TokenResponse, UsuarioConRolesResponse, UsuarioRolResponse, RolResponse
from security import verify_password, create_access_token, get_current_user

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
