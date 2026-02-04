use crate::git_runner::GitRunner;
use crate::AppError;

pub struct RepoService {
    root: String,
}

impl RepoService {
    pub fn new(path: String) -> Result<Self, AppError> {
        let output = GitRunner::run(
            vec!["rev-parse".to_string(), "--show-toplevel".to_string()],
            path,
        )?;
        let root = output.trim().to_string();
        if root.is_empty() {
            return Err(AppError::new("Not a git repository"));
        }
        Ok(Self { root })
    }

    pub fn status(&self) -> Result<String, AppError> {
        GitRunner::run(vec!["status".to_string()], self.root.clone())
    }

    pub fn diff(&self) -> Result<String, AppError> {
        GitRunner::run(vec!["diff".to_string()], self.root.clone())
    }
}
