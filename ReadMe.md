## Intro
This Plugin is based on [tEasyFtp](https://forums.alliedmods.net/showthread.php?p=1629724) & [tAutoDemoUpload](https://forums.alliedmods.net/showthread.php?p=1517461), which are both not longer supported.  
Credits to Thrawn, this wouldnt exist without his work.

This is also the reason why the syntax is mixed & weird at times, I mostly fixed compilation erros and minorly changed behaviour in some cases.

One interesting additional feature is the ability to send the download link of every demo to a discord textchannel.

## How to use
1. Confirm you have [SourceMod](https://www.sourcemod.net/downloads.php) and [MetaMod:Source](https://metamodsource.net/downloads.php) running on your server.
2. Download this [repository](https://github.com/MoritzLoewenstein/AutoDemoUpload/archive/master.zip) and unzip it to your /csgo folder on your server.
3. Set your FTP options in `addons/sourcemod/configs/RemoteTargets.cfg` in `"demos"`.
4. Make sure the plugin is running (`sm plugins list`)
5. It should start uploading the demo after executing `tv_record` and `tv_stoprecord` and  
   announce the download link in allchat after completing the upload.


## Options

### FTP Server
The FTP Server options are stored in `addons/sourcemod/configs/RemoteTargets.cfg`

1. Add your data in these self-explanatory options:
```
"RemoteTargets"
{
	"demos"
	{
		"host"		""
		"port"		"21"
		"user"		""
		"password"	""
		"path"		"/demos"
		"ssl"		"try"
		"CreateMissingDirs"	"1"
	}
}
```

2. If you changed `demos` to another name (e.g. `new_name`), then set `sm_tautodemoupload_ftptarget "new_name"`.

### Demo compression
Bzip is already included, you just have to set `sm_tautodemoupload_bzip2` to a value between `0-9`.  
`0` -> no compression  
`9` -> max compression

### Delete Demo after upload
To delete the demo after upload (and the compressed demo), set `sm_tautodemoupload_delete 1`.

### Send Download Link to Discord Channel
1. create a discord textchannel and set up a webhook.
2. set these two convars:
   - `sm_teasyftp_discord_webhook <your_discord_webhook>`
   - `sm_teasyftp_announce_on_discord 1`

### Change Format of Message
`sm_teasyftp_announce_format "%map: %dl_url"`  
use `%map`, `%dl_url` & `%host`

### Enable/Disable
You can enable and disable this Plugin with `sm_tautodemoupload_enable`.  
`1` -> enabled  
`0` -> disabled

## FAQ

### How can I set the local demo path?
The demo path gets parsed from the `tv_record` command, e. g. `tv_record a/b/c/demoname.dem`.  
Make sure the directory exists. When uploading, the demo will be in `targetfolder/demoname.dem`,  
NOT `targetfolder/a/b/c/demoname.dem`.

### How can I fix the `SSL connect error`?
Try setting `ssl` to `none` in your RemoteTargets.cfg.







