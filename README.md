This is a simple standalone Ruby class I wrote as an exercise to get familiar with Ruby. I don't recommend anyone actually use this without reviewing for themselves. I'm not responsible for anything that happens from its use. Some of this is based off the file-find library for Ruby.

    * Locates all files in a specified directory with the world execute permission bit enabled (defaults to current directory)
    * Traverses directories recursively (to any specified max-depth)
    * Removes world execute permission from files without altering any other permission
    * Reports progress to stdout

This repo also includes a short script to use the class. It accepts:

	* -p – Directory to process (defaults to current)
	* -r – Update in subdirectories recursively
	* -v – Verbosely list updated files during processing
	* -a – Also update hidden dot files (e.g. `.gitignore`)
	* -m – Maximum depth of subdirectories to process (with level 1 being given path)
	* -h – Displays help message

Some basic testing also in place with `rake test`. Uses fakefs library to prevent potentially screwing up real local file system.
