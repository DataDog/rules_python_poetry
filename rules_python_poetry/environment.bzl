"""
Poetry Environment Repository

Simply exports requirement.txt files based on poetry lock files.
"""

def _symlink_project_files(repository_ctx):
    raw = repository_ctx.path("pyproject.toml.original")
    repository_ctx.symlink(
        repository_ctx.attr.project,
        raw,
    )

    # Strip local deps. These need special import rules in your bazel files.
    res = repository_ctx.execute(
        ["sed", "/path =/d", raw],
    )
    output = repository_ctx.path("pyproject.toml")
    repository_ctx.file(
        output,
        content = res.stdout,
    )
    repository_ctx.symlink(
        repository_ctx.attr.lock,
        repository_ctx.path("poetry.lock"),
    )

def _run_export(repository_ctx, output, without_hashes = False, dev = False):
    repository_ctx.execute(
        [
            "poetry",
            "export",
            "-f",
            "requirements.txt",
            "-o",
            repository_ctx.path(output),
        ] + (["--without-hashes"] if without_hashes else []) + (["--dev"] if dev else []),
        quiet = False,
    )

def _export_requirements(repository_ctx):
    without_hashes = repository_ctx.attr.without_hashes
    _run_export(repository_ctx, "requirements.txt", without_hashes)
    _run_export(repository_ctx, "requirements-dev.txt", without_hashes, True)

def _poetry_environment_impl(repository_ctx):
    repository_ctx.file("BUILD")
    _symlink_project_files(repository_ctx)
    _export_requirements(repository_ctx)

poetry_environment = repository_rule(
    attrs = {
        "project": attr.label(
            mandatory = True,
            allow_single_file = True,
            doc = "The label of the pyproject.toml file.",
        ),
        "lock": attr.label(
            mandatory = True,
            allow_single_file = True,
            doc = "The label of the poetry.lock file.",
        ),
        "without_hashes": attr.bool(
            mandatory = False,
            default = False,
            doc = "Whether hashes should be skipped in the rendered requirements",
        ),
    },
    implementation = _poetry_environment_impl,
)
