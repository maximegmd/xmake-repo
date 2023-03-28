package("mono")

    set_homepage("https://www.mono-project.com/")
    set_description("Cross platform, open source .NET development framework")

    set_urls("https://download.mono-project.com/sources/mono/mono-$(version).tar.xz",
             {version = function (version) return version:gsub("%+", ".") end})

    add_versions("6.8.0+123", "e2e42d36e19f083fc0d82f6c02f7db80611d69767112af353df2f279744a2ac5")
    add_versions("6.12.0+182", "57366a6ab4f3b5ecf111d48548031615b3a100db87c679fc006e8c8a4efd9424")

    add_includedirs("include", "include/mono-2.0", "include/mono")

    on_install("macosx", "linux", function (package)
        local configs = {"--disable-silent-rules", "--enable-nls=no"}
        import("package.tools.autoconf").install(package, configs)
    end)

    on_install("windows", function (package)
        import("core.tool.toolchain")
        
        local version = package:version_str()
        local base_dir = package:scriptdir()
        local src_path = path.join(base_dir, "msvc", version)

        os.cp(path.join(src_path, "msvc", "**"), "msvc")
        os.cp(path.join(src_path, "mono", "mini", "*"), path.join("mono", "mini"))
        os.cp(path.join(src_path, "mono", "utils", "*"), path.join("mono", "utils"))

        local solutionFile = package:config("shared") and "msvc/libmono-dynamic.vcxproj" or "msvc/libmono-static.vcxproj"
        local arch = package:is_arch("x86") and "Win32" or "x64"
        local mode = package:debug() and "Debug" or "Release"
        local configs = { solutionFile }
        table.insert(configs, "/property:Configuration=" .. mode)
        table.insert(configs, "/property:Platform=" .. arch)
        table.insert(configs, "/p:MONO_TARGET_GC=sgen")
        import("package.tools.msbuild").build(package, configs)

        local solutionFile = "msvc/mono.vcxproj"
        local configs = { solutionFile }
        table.insert(configs, "/property:Configuration=" .. mode)
        table.insert(configs, "/property:Platform=" .. arch)
        table.insert(configs, "/p:MONO_TARGET_GC=sgen")
        import("package.tools.msbuild").build(package, configs)

        local out_path = path.join("msvc", "build", "sgen", arch)
        local lib_path = path.join(out_path, "lib", mode)
        local bin_path = path.join(out_path, "bin", mode)
        local include_path = path.join("msvc", "include", "**")

        os.cp(path.join(lib_path, "*.lib"), package:installdir("lib"))
        os.cp(include_path, package:installdir("include"))
        
        package:add("links", "*.lib")

        if package:config("shared") then
            os.cp(path.join(bin_path, "*.dll"), package:installdir("bin"))
        end
    end)

    on_test(function (package)
        assert(package:has_cfuncs("mono_object_get_class", {includes = "mono/metadata/object.h"}))
    end)

