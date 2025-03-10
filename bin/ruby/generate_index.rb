# Generate folder maps / index html pages using ruby.
# Similar to the command `tree -H ./ > index.html`  used to
# output a directory structure listing to an index.html file
# for use locally or on a server.  This is an encapsulated  version
# of the shell script described below, rewritten to provide addtional
# control of output and learn to use Ruby as a language to replace
# complex oneliners or shell scripts.
#
# Options for: ignoring all files or directories, ignore named files/directories,
#              ignore files of `type`, set page title, generate html,
#              generate markdown, map dirname href to dirname/index.html or
#              do not add a link to the directory name.
#
# Original shell script
#
# 1) First, create a main index from the current folder, excluding
#    folders where necessary and only showing specific files.
#
# rg --files \
#   --glob '!scripts*' \
    # --glob '!data*' \
    # --glob '!font*' \
    # --glob '!styles*' \
    # --glob '!img*' | \
    # tree --fromfile \
    # --noreport \
    # -T "unforswearing.com/folio" \
    # -P '*index.html|*.pdf' \
    # -H ./ >| folio.html
#
# 2) Next, find all sub directories and create an index map for each,
#    skipping where required
#
#  fd . -t d -d 1 \
    # --exclude=actionkit \
    # --exclude=copper_app_faq \
    # --exclude=gas_send_email | \
    # while read directory; do
    #  cd "$directory"
    #  rg --files --glob '!scripts*' --glob '!data*' --glob '!font*' --glob '!styles*' --glob '!img*' | tree --fromfile --noreport -T "unforswearing.com/folio/$directory" -P '*index.html|*.pdf' -H ./ >| index.html
    #  cd ..
    # done

# Get a list of all directories in `Dir.pwd`
# Dir.entries(Dir.pwd).select {|each| File.directory?(File.join(Dir.pwd, each))}

# class workingDir
# workingDir.pwd
# workingDir.files -> []
# workingDir.dirs -> []
#

# class html
# html.cssFile
# html.template -> {}
# html.html -> {
#   p('text', style='style'), br.., div.., span.., etc
# }

def print_dirfile_listing()
  Dir.entries(Dir.pwd)
end

# def filter_filename(name) -> exclude if file name matches `name`
# def filter_dirname(name) -> exclude if dir name matches `name`
# def filter_extension(ext) -> exclude if extension matches `ext`
# def filter_pattern(regex) -> exclude if item of any type matches `regex`
# def filter_include_only(type:str, arg:arr) ->
#     exlude all items except those of `type` ("name", "ext", "regex")
#     that matches `arg` (filename, dirname, extension, regex)

def filter_only_dirs()
  listing = print_dirfile_listing()
  listing.select { |item|
    File.directory?(File.join(Dir.pwd, item))
  }
end

if ARGV
  puts filter_only_dirs()
end
