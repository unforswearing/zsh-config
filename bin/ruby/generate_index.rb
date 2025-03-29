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

# WorkingDir::pwd()
# WorkingDir::contents()
# WorkingDir::dirs()
# WorkingDir::files()
module WorkingDir
  def self.pwd()
    return Dir.pwd
  end
  def self.contents()
    return Dir.entries(self.pwd())
  end
  def self.dirs()
    @collector = []
    @listing = self.contents()
    @listing.select { |directory|
      if File.directory?(directory)
        @collector.append(directory)
      end
    }
    return @collector
  end
  def self.files()
    @collector = []
    @listing = self.contents()
    @listing.select { |file|
      if File.file?(file)
        @collector.append(file)
      end
    }
    return @collector
  end
end

module HTML
  @title = File.split(File.expand_path(WorkingDir::pwd())).pop()
  def self.template()
  end
  def self.tag()
    # p('text', style='style'), br.., div.., span.., etc
  end
end

# example: $site/folio/folio.html
ui = {
  indentpipe => "│",
  branchline => "─"
  dirbranch => "├",
  lastbranch => "└"
}

module Filter
  # exclude if file name matches `name`
  def self.filename(name)
  end
  # exclude if dir name matches `name`
  def self.dirname(name)
  end
  # exclude if extension matches `ext`
  def self.extension(ext)
  end
  # exclude if item of any type matches `regex`
  def self.pattern(regex)
  end
  # exlude all items except those of `type` ("name", "ext", "regex")
  # that matches `arg` (filename, dirname, extension, regex)
  def self.include_only(type, arr)
  end
end

