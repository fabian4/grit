use std::process::Command;

use crate::AppError;

pub struct GitRunner;

impl GitRunner {
    pub fn run(args: Vec<String>, cwd: String) -> Result<String, AppError> {
        let mut cmd = Command::new("git");
        cmd.current_dir(cwd);
        cmd.arg("-c").arg("core.pager=cat");
        cmd.arg("-c").arg("color.ui=false");
        for arg in args {
            cmd.arg(arg);
        }

        let output = cmd.output()?;
        let stdout = String::from_utf8_lossy(&output.stdout).to_string();
        let stderr = String::from_utf8_lossy(&output.stderr).to_string();

        if !output.status.success() {
            let mut msg = String::new();
            if !stdout.trim().is_empty() {
                msg.push_str(stdout.trim());
            }
            if !stderr.trim().is_empty() {
                if !msg.is_empty() {
                    msg.push('\n');
                }
                msg.push_str(stderr.trim());
            }
            if msg.trim().is_empty() {
                msg = format!("git exited with status {}", output.status);
            }
            return Err(AppError::new(msg));
        }

        if !stdout.is_empty() {
            Ok(stdout)
        } else {
            Ok(stderr)
        }
    }
}
