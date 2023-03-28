package("mono")

    set_homepage("https://www.mono-project.com/")
    set_description("Cross platform, open source .NET development framework")

    set_urls("https://github.com/mono/mono.git")

    add_versions("mono-6.8.0.123")
    add_versions("mono-6.12.0.190")

    add_includedirs("include/mono-2.0")

    on_install("macosx", "linux", function (package)
        local configs = {"--disable-silent-rules", "--enable-nls=no"}
        import("package.tools.autoconf").install(package, configs)
    end)

    on_install("windows", function (package)
        import("core.tool.toolchain")

        local solutionFile = "msvc/mono.sln"
        local arch = package:is_arch("x86") and "Win32" or "x64"
        local mode = package:debug() and "Debug" or "Release"
        local configs = {solutionFile}
        table.insert(configs, "/property:Configuration=" .. mode)
        table.insert(configs, "/property:Platform=" .. arch)
        table.insert(configs, "/p:MONO_TARGET_GC=sgen")
        import("package.tools.msbuild").build(package, configs)
    end)

    on_test(function (package)
        assert(package:has_cfuncs("mono_object_get_class", {includes = "mono/metadata/object.h"}))
    end)

