import os
import sys
import json
import urllib.request
import urllib.error
import ssl

def main():
    # Fetch environment variables
    repo = os.environ.get("GITHUB_REPOSITORY")
    run_id = os.environ.get("GITHUB_RUN_ID")
    run_number = os.environ.get("GITHUB_RUN_NUMBER")
    ref_name = os.environ.get("GITHUB_REF_NAME")
    commit_sha = os.environ.get("GITHUB_SHA")
    token = os.environ.get("GITHUB_TOKEN")
    telegram_bot_token = os.environ.get("TELEGRAM_BOT_TOKEN")
    telegram_chat_id = os.environ.get("TELEGRAM_CHAT_ID")

    if not all([repo, run_id, token, telegram_bot_token, telegram_chat_id]):
        print("Error: Missing required environment variables.")
        sys.exit(1)

    # Disable SSL verification if needed (to prevent cert issues on some runners)
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE

    # Step 1: List jobs for the workflow run
    jobs_url = f"https://api.github.com/repos/{repo}/actions/runs/{run_id}/jobs"
    print(f"Listing jobs from: {jobs_url}")
    
    req = urllib.request.Request(
        jobs_url,
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": "application/vnd.github+json",
            "User-Agent": "AmazonFish-DevOps"
        }
    )
    
    try:
        with urllib.request.urlopen(req, context=ctx) as res:
            jobs_data = json.loads(res.read().decode("utf-8"))
    except Exception as e:
        print(f"Error fetching jobs: {e}")
        sys.exit(1)

    jobs = jobs_data.get("jobs", [])
    print(f"Found {len(jobs)} jobs in this run.")

    consolidated_log_path = f"logs_pipeline_run_{run_number}.txt"
    
    with open(consolidated_log_path, "w", encoding="utf-8") as out:
        out.write("================================================================\n")
        out.write(f"🐟 AMAZONFISH - LOGS COMPLETOS DEL PIPELINE (RUN #{run_number})\n")
        out.write(f"Rama: {ref_name} | Commit: {commit_sha}\n")
        out.write("================================================================\n\n")

        # Step 2: Download logs for each completed job
        for job in jobs:
            job_id = job.get("id")
            job_name = job.get("name")
            job_status = job.get("status")
            
            # Avoid logging notify-end's own running logs to prevent recursion/locking
            if "Notificar Resultado" in job_name:
                continue
                
            print(f"Processing job '{job_name}' (ID: {job_id}, Status: {job_status})...")
            
            if job_status != "completed":
                print(f"Skipping job '{job_name}' because status is '{job_status}'.")
                continue

            log_url = f"https://api.github.com/repos/{repo}/actions/jobs/{job_id}/logs"
            log_req = urllib.request.Request(
                log_url,
                headers={
                    "Authorization": f"Bearer {token}",
                    "Accept": "application/vnd.github+json",
                    "User-Agent": "AmazonFish-DevOps"
                }
            )
            
            try:
                with urllib.request.urlopen(log_req, context=ctx) as log_res:
                    log_text = log_res.read().decode("utf-8", errors="ignore")
                    
                    out.write("================================================================\n")
                    out.write(f"⚙️ JOB: {job_name} (Status: {job.get('conclusion')})\n")
                    out.write("================================================================\n")
                    out.write(log_text)
                    out.write("\n\n")
                    print(f"Successfully appended logs for job '{job_name}'.")
            except Exception as e:
                print(f"Error downloading log for job {job_name}: {e}")
                out.write("================================================================\n")
                out.write(f"⚙️ JOB: {job_name} (Error al descargar logs)\n")
                out.write("================================================================\n")
                out.write(f"Error: {e}\n\n")

    # Step 3: Send the consolidated file to Telegram
    if os.path.exists(consolidated_log_path) and os.path.getsize(consolidated_log_path) > 150:
        print(f"Sending consolidated logs to Telegram...")
        cmd = (
            f'curl -s -X POST "https://api.telegram.org/bot{telegram_bot_token}/sendDocument" '
            f'-F "chat_id={telegram_chat_id}" '
            f'-F "document=@{consolidated_log_path}" '
            f'-F "caption=📄 Logs consolidados del Pipeline (Run #{run_number})"'
        )
        os.system(cmd)
        print("Done.")
    else:
        print("Consolidated log file is too small or does not exist.")

if __name__ == "__main__":
    main()
