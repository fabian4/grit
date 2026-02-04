mod git_runner;
mod repo_service;

pub use repo_service::RepoService;

#[derive(Debug, Clone, thiserror::Error, uniffi::Error)]
pub enum AppError {
    #[error("{0}")]
    Message(String),
}

impl AppError {
    pub fn new(message: impl Into<String>) -> Self {
        AppError::Message(message.into())
    }
}

impl From<std::io::Error> for AppError {
    fn from(value: std::io::Error) -> Self {
        AppError::new(value.to_string())
    }
}

uniffi::include_scaffolding!("interface");
