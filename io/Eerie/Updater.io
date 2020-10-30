//metadoc Updater category API
/*metadoc Updater description 
This proto is responsible for package updates. Notice, `Updater` updates only
locally (i.e. from a local directory). For downloading an updated package before
using `Updater` see [[Downloader]].*/

Updater := Object clone do (

    /*doc Updater package 
    The `Package` dependencies of which the updater should update.*/
    package := nil
    
    /*doc Updater newer 
    An update (`Package`) for some dependency of `Updater package`.*/
    newer := nil

    # The `Package`, which the updater should update.
    _targetPackage := nil

    # version, to which the dependency will be updated
    _targetVersion := nil

    /*doc Updater with(package, newer, version)
    Initializer, where:
    - package - the `Package` dependencies of which the updater should update
    - newer - a new version of a `package` dependency*/
    with := method(package, newer,
        klone := self clone
        klone package = package
        klone newer = newer
        klone)

    /*doc Updater update 
    Install update.*/
    update := method(
        self package _checkHasDep(self newer)
        self _checkInstalled
        self _initTargetVersion

        version := self _highestVersion

        self _logUpdate(version)
        self package _checkGitBranch(self newer)
        self _checkGitTag(version)
        self _removeOld
        self _installNew)

    # check whether `package` has target dependency
    _checkInstalled := method(
        self _targetPackage = package packageNamed(self newer name)
        if (self _targetPackage isNil, 
            Exception raise(NotInstalledError with(self newer name))))

    # set target version
    _initTargetVersion := method(
        if (self _targetVersion isNil not, return)

        addons := self package config at("addons")
        dep := addons detect(at("name") == self newer name)
        self _targetVersion = SemVer fromSeq(dep at("version")))

    # find highest available version
    _highestVersion := method(
        highest := self _targetVersion

        self _availableVersions foreach(ver, 
            if (ver <= self _targetVersion and(
                ver isPre == self _targetVersion isPre), 
                highest = ver))

        highest)

    # collect available versions from git tags as a list
    _availableVersions := method(
        cmdOut := Eerie sh("git tag", true, self newer dir path)
        res := cmdOut stdout splitNoEmpties("\n") map(tag, SemVer fromSeq(tag))
        if (res isEmpty,
            Exception raise(NoVersionsError with(newer name)))
        res)

    _logUpdate := method(version,
        if (version > self _targetPackage version) then (
            Logger log("⬆ [[cyan bold;Updating [[reset;" ..
                "#{self _targetPackage name} " ..
                "from v#{self _targetPackage version asSeq} " ..
                "to v#{version asSeq}", "output")
        ) elseif (version < self _targetPackage version) then (
            Logger log(
                "⬇ [[cyan bold;Downgrading [[reset;" .. 
                "#{self _targetPackage name} " ..
                "from v#{self _targetPackage version asSeq} " ..
                "to v#{version asSeq}", "output")
        ) else (
            Logger log(
                "☑  #{self _targetPackage name} " .. 
                "v#{self _targetPackage version asSeq} " ..
                "is already updated", "output")))

    _checkGitTag := method(version,
        Eerie sh("git checkout tags/#{version originalSeq}", 
            false,
            self newer dir path))

    # removes the old version of the dependency
    _removeOld := method(
        old := self package packageNamed(self newer name)
        self package removePackage(old))

    # installs the `newer` package
    _installNew := method(
        installer := Installer with(self package)
        installer install(self newer))

)

# Updater error types
Updater do (

    //doc Updater NoVersionsError
    NoVersionsError := Eerie Error clone setErrorMsg(
        "The package '#{call evalArgAt(0)}' has no tagged versions.")

    //doc Updater NotInstalledError
    NotInstalledError := Eerie Error clone setErrorMsg(
        "The dependency '#{call evalArgAt(0)}' is not installed.")

)
