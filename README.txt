B"H.


A Github backupper

Attempts to use as few API requests as possible, in order to prevent rate-limiting frustration.
Also touches the file system as seldom as possible, yielding better performance and less disk writes for slow and limited-writes drives.

Downloads items which have their own Git repos; more can possibly be gotten by making a Github-API-to-onthefly-git-repo-interface utility/service and using this as a new git repo itemtype.

Inspired by <http://joeyh.name/code/github-backup/>.



Licensed BSD.
