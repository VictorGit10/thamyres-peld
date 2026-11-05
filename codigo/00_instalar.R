# ==============================================================================
# codigo/00_instalar.R
# Verifica e instala os pacotes R necessários para o kit PELD
# ==============================================================================

# Biblioteca do usuário: funciona em qualquer máquina.
# No Windows, R_LIBS_USER aponta para a biblioteca pessoal (ex.:
# C:/Users/<usuario>/AppData/Local/R/win-library/<versao>).
user_lib <- Sys.getenv("R_LIBS_USER")
if (!nzchar(user_lib)) {
  user_lib <- .libPaths()[1]
}
if (!dir.exists(user_lib)) {
  dir.create(user_lib, recursive = TRUE, showWarnings = FALSE)
}
.libPaths(c(user_lib, .libPaths()))

pacotes_necessarios <- c(
  "tidyverse",
  "janitor",
  "DBI",
  "RSQLite",
  "jsonlite",
  "httr2",
  "scales"
)

pacotes_instalados <- installed.packages(lib.loc = .libPaths())[, "Package"]
faltantes <- setdiff(pacotes_necessarios, pacotes_instalados)

if (length(faltantes) > 0) {
  message("Instalando pacotes faltantes em ", user_lib, ": ",
          paste(faltantes, collapse = ", "))
  tipo <- if (.Platform$OS.type == "windows") "binary" else "source"
  install.packages(faltantes, lib = user_lib,
                   repos = "https://cloud.r-project.org", type = tipo)
} else {
  message("Todos os pacotes necessarios estao instalados:")
  for (pkg in pacotes_necessarios) {
    ver <- as.character(packageVersion(pkg, lib.loc = .libPaths()))
    message("  - ", pkg, " (versao ", ver, ")")
  }
}
