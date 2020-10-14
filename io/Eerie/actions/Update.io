Update := Eerie Action clone do(
    name := "Update"
    asVerb := "Updating"

    prepare := method(self pkg downloader hasUpdates)

    execute := method(
        self pkg runHook("beforeUpdate")

        self pkg downloader canDownload(downloader uri) ifFalse(
            Exception raise(
                Downloader FailedDownloadError with(downloader uri)))

        self pkg downloader update
        installer := Installer with(self pkg) \
            setRoot(Eerie addonsDir) \
                setDestBinName(Eerie globalBinDirName)

        installer install(Eerie isGlobal)
        # self pkg loadInfo

        self pkg runHook("afterUpdate")

        true)
)