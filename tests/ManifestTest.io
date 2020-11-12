Importer addSearchPath("io/Eerie/Package/Structure")

ManifestTest := UnitTest clone do (

    testDeps := method(
        manifest := Manifest with(
            File with(
                "tests/_packs/AFakePack/#{Eerie manifestName}" interpolate))
        expected := list()
        
        dep := Package Dependency clone
        dep name = "CFakePack"
        dep version = SemVer fromSeq("0.1")
        dep url = "tests/_packs/CFakePack"
        expected append(dep)
        
        dep = dep clone
        dep name = "BFakePack"
        dep url = "tests/_packs/BFakePack"
        expected append(dep)

        result := manifest packs

        expected foreach(n, item, 
            assertEquals(item name, result at(n) name)
            assertEquals(item version, result at(n) version)
            assertEquals(item url, result at(n) url)))

    testFileExists := method(
        e := try (Manifest with(
            File with(
                "tests/_fpacks/NotPack/#{Eerie manifestName}" interpolate)))
        assertEquals(e error type, Manifest FileNotExistsError type))

    testValueForKey := method(
        manifest := Manifest clone
        expected := 42
        manifest _map := Map clone atPut(
            "foo", Map clone atPut(
                "bar", Map clone atPut(
                    "baz", expected)))
        assertEquals(expected, manifest valueForKey("foo.bar.baz")))

    testValidation := method(
        self _assertManifestError("{}")

        self _assertManifestError("""{"name": "Test"}""")

        self _assertManifestError("""{
            "name": "Test", 
            "version": "0.1.0"
            }""")

        self _assertManifestError("""{
            "name": "Test", 
            "version": "0.1.0",
            "author": "Test"
            }""")

        self _assertManifestError("""{
            "name": "Test", 
            "version": "0.1.0",
            "author": "Test",
            "url": ""
            }""")

        self _assertManifestError("""{
            "name": "Test", 
            "version": "0.1.0",
            "author": "Test",
            "url": "path/to/package"
            }""")

        self _assertManifestError("""{
            "name": "Test", 
            "version": "0.1.0",
            "author": "Test",
            "url": "path/to/package",
            "protos": ""
            }""")

        self _assertManifestError("""{
            "name": "Test", 
            "version": "0.1.0",
            "author": "Test",
            "url": "path/to/package",
            "protos": [],
            "packs": [ { } ] 
            }""")

        self _assertManifestError("""{
            "name": "Test", 
            "version": "0.1.0",
            "author": "Test",
            "url": "path/to/package",
            "protos": [],
            "packs": [
                    { 
                        "name": "Test"
                    }
                ]
            }""")

        # shouldn't raise an exception if protos is empty array
        self _assertManifestLegal("""{
            "name": "Test", 
            "version": "0.1.0",
            "author": "Test",
            "url": "path/to/package",
            "protos": []
            }""")

        # "packs" is optional, so an empty array shouldn't raise an exception
        self _assertManifestLegal("""{
            "name": "Test", 
            "version": "0.1.0",
            "author": "Test",
            "url": "path/to/package",
            "protos": [],
            "packs": []
            }""")

        # this shouldn't raise an exception, the dependency supposed to be
        # published
        self _assertManifestLegal("""{
            "name": "Test", 
            "version": "0.1.0",
            "author": "Test",
            "url": "path/to/package",
            "protos": [],
            "packs": [
                    { 
                        "name": "Test",
                        "version": "0.1"
                    }
                ]
            }"""))

    _assertManifestError := method(contents,
        file := File with("tests/deleteme") setContents(contents)
        e := try (Manifest with(file) validate)
        assertEquals(
            e error type,
            Manifest InsufficientManifestError type)
        file remove)

    _assertManifestLegal := method(contents,
        file := File with("tests/deleteme") setContents(contents)
        Manifest with(file) validate
        file remove)

    testCheckShortenedVersion := method(
        manifest := Manifest with(
            File with(
                "tests/_packs/BFakePack/#{Eerie manifestName}" interpolate))
        manifest version = SemVer fromSeq("0.1")
        e := try (manifest _checkVersionShortened)
        assertEquals(e error type, 
            Manifest VersionIsShortenedError type))

    testCheckReadme := method(
        manifest := Manifest with(
            File with(
                "tests/_packs/AFakePack/#{Eerie manifestName}" interpolate))
        
        e := try (manifest _checkReadme)
        assertEquals(e error type, Manifest ReadmeError type)

        # package with readme field
        manifest = Manifest with(
            File with(
                "tests/_packs/DFakePack/#{Eerie manifestName}" interpolate))
        readme := manifest file parentDirectory \
            fileNamed("README.md") create remove

        # it doesn't exist
        e := try (manifest _checkReadme)
        assertEquals(e error type, Manifest ReadmeError type)

        # make it exists, but empty
        readme create
        e := try (manifest _checkReadme)
        assertEquals(e error type, Manifest ReadmeError type)
        
        readme setContents("# " .. manifest name)
        # should pass now
        manifest _checkReadme
        readme remove)

    testCheckLicense := method(
        manifest := Manifest with(
            File with(
                "tests/_packs/AFakePack/#{Eerie manifestName}" interpolate))
        
        e := try (manifest _checkLicense)
        assertEquals(e error type, Manifest LicenseError type)

        # package with license field
        manifest = Manifest with(
            File with(
                "tests/_packs/DFakePack/#{Eerie manifestName}" interpolate))
        license := manifest file parentDirectory \
            fileNamed("LICENSE") create remove

        # it doesn't exist
        e := try (manifest _checkLicense)
        assertEquals(e error type, Manifest LicenseError type)

        # make it exists, but empty
        license create
        e := try (manifest _checkLicense)
        assertEquals(e error type, Manifest LicenseError type)
        
        license setContents(manifest name)
        # should pass now
        manifest _checkLicense
        license remove)

    testDescriptionCheck := method(
        # package with empty description
        manifest := Manifest with(
            File with(
                "tests/_packs/BFakePack/#{Eerie manifestName}" interpolate))

        e := try (manifest _checkDescription)
        assertEquals(e error type, Manifest NoDescriptionError type)

        manifest = Manifest with(
            File with(
                "tests/_packs/AFakePack/#{Eerie manifestName}" interpolate))
        manifest _checkDescription)

)
