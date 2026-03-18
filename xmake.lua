add_requires("cosmocc")
add_packages("cosmocc")
set_toolchains("@cosmocc")

target("example_hello_x64")
    set_kind("static")
    on_load(function (target)
        target:set("toolset","cc", path.join(target:pkg("cosmocc"):installdir(),"bin","x86_64-unknown-cosmo-cc"))
        target:set("toolset","ar",  path.join(target:pkg("cosmocc"):installdir(),"bin","x86_64-unknown-cosmo-ar"))
    end)
    set_plat("unknown")
    set_arch("x86-64")
    add_files("example_hello.c")
    add_cflags("-mcosmo", {force = true})
target_end()


target("example_hello_aarch64")
    set_kind("static")
    on_load(function (target)
        target:set("toolset","cc",path.join(target:pkg("cosmocc"):installdir(),"bin","aarch64-unknown-cosmo-cc"))
        target:set("toolset","ar",path.join(target:pkg("cosmocc"):installdir(),"bin","aarch64-unknown-cosmo-ar"))
    end)
    set_plat("unknown")
    set_arch("aarch64")
    add_files("example_hello.c")
    add_cflags("-mcosmo", {force = true})
target_end()


target("main_x64")
    add_deps("example_hello_x64")
    set_kind("binary")
    set_plat("unknown")
    set_arch("x86-64")
    on_load(function (target)
        target:set("toolset","cc",path.join(target:pkg("cosmocc"):installdir(),"bin","x86_64-unknown-cosmo-cc"))
        target:set("toolset","cxx",path.join(target:pkg("cosmocc"):installdir(),"bin","x86_64-unknown-cosmo-c++"))
        target:set("toolset","ld",path.join(target:pkg("cosmocc"):installdir(),"bin","x86_64-unknown-cosmo-c++"))
        target:set("toolset","ar",path.join(target:pkg("cosmocc"):installdir(),"bin","x86_64-unknown-cosmo-ar"))
    end)
    add_files("main.c")
    add_links("example_hello_x64")
    add_cflags("-mcosmo", {force = true})
target_end()


target("main_aarch64")
    add_deps("example_hello_aarch64")
    set_kind("binary")
    set_plat("unknown")
    set_arch("aarch64")
    on_load(function (target)
        target:set("toolset","cc",path.join(target:pkg("cosmocc"):installdir(),"bin","aarch64-unknown-cosmo-cc"))
        target:set("toolset","cxx",path.join(target:pkg("cosmocc"):installdir(),"bin","aarch64-unknown-cosmo-c++"))
        target:set("toolset","ld",path.join(target:pkg("cosmocc"):installdir(),"bin","aarch64-unknown-cosmo-c++"))
        target:set("toolset","ar",path.join(target:pkg("cosmocc"):installdir(),"bin","aarch64-unknown-cosmo-ar"))
    end)
    add_files("main.c")
    add_links("example_hello_aarch64")
target_end()


target("main.com")
    add_deps("main_x64", "main_aarch64")
    add_links("build/unknown/x86-64/$(mode)/main_x64", "build/unknown/aarch64/$(mode)/main_aarch64")
    set_plat("unknown")
    set_arch("unknown")
    set_kind("binary")
    -- on_load(function (target)
    --     import("core.project.project")
    --     -- TODO: add "links" here
    --     -- local deps=target:get("deps")
    --     -- for __, dep in ipairs(deps) do
    --     -- end

    --     -- target:set("links", links)
    -- end)
    on_link(function (target,opt) -- merging x64 and aarch64 APE executables together
        local targetfile = target:targetfile()
        local link_files = target:get("links")
        local target_mtime = 0
        if os.isfile(targetfile) then
            target_mtime = os.mtime(targetfile)
        end

        local needs_linking = false
        if target_mtime > 0 then 
            for _, link_file in ipairs(link_files) do
                if os.isfile(link_file) then
                    local file_mtime = os.mtime(link_file)
                    if file_mtime > target_mtime then
                        needs_linking = true
                        break
                    end
                else
                    needs_linking = true
                    break
                end
            end
        end
        if target_mtime > 0 and not needs_linking then
            return
        end
        cprint("${bright green}[ %s]: ${magenta}%s", opt.progress, "linking.$(mode) ape executables...")
        local apelink=path.join(target:pkg("cosmocc"):installdir(),"bin","apelink") -- get from cosmocc package
        local argv={"-o",targetfile}
        for _, link_file in ipairs(link_files) do
            table.insert(argv,link_file)
        end
        if not os.isdir(target:targetdir()) then
            os.mkdir(target:targetdir())
        end
        os.execv(apelink, argv, {shell = true})
    end)

target_end()




task("genClangdConfig")
    on_run(function ()
        import("core.base.option")
        import("core.project.project")
        import("core.project.config")
        
        -- Check if cosmocc package exists
        if not has_package("cosmocc") then
            print("Error: cosmocc package not found. Please add it to your project.")
            return
        end
        
        print("Generating .clangd configuration...")
        -- Get any target in the project to access package information
        local any_target
        for _, t in pairs(project.targets()) do
            any_target = t
            break
        end
        
        if not any_target then
            print("Error: No targets found in project.")
            return
        end
        
        -- Get cosmocc installation path
        local cosmocc_path = any_target:pkg("cosmocc"):installdir()
        local include_path = path.join(cosmocc_path, "include")
        local normalize_inc = path.join(include_path, "libc/integral/normalize.inc")
        
        -- Get current working directory
        local cwd = os.curdir()
        
        -- Build .clangd file content
        local clangd_content = "CompileFlags:\n  Add: \n"
        clangd_content = clangd_content .. string.format('    - "-I%s"\n', include_path)
        clangd_content = clangd_content .. string.format('    - "-include%s"\n', normalize_inc)
        clangd_content = clangd_content .. '    - "-D_COSMO_SOURCE"\n'
        clangd_content = clangd_content .. '    - "-nostdinc"\n'
        clangd_content = clangd_content .. '    - "-nostdlib"\n'
        
        -- Write .clangd file
        local clangd_file = path.join(cwd, ".clangd")
        local file = io.open(clangd_file, "w")
        if file then
            file:write(clangd_content)
            file:close()
            print(string.format("Successfully generated .clangd at: %s", clangd_file))
        else
            print("Error: Failed to write .clangd file.")
        end
    end)
    
    set_menu {
        usage = "xmake genClangdConfig [options]",
        description = "Generate .clangd configuration file for Cosmopolitan libC",
        options = {
            {nil, "force", "k", nil, "Force regeneration of .clangd file"},
        }
    }
task_end()