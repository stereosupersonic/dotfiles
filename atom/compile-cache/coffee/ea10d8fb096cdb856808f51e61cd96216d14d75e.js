(function() {
  var CompositeDisposable, Path, RAILS_ROOT, RailsOpenRspecView, fs;

  RailsOpenRspecView = require('./rails-open-rspec-view');

  CompositeDisposable = require('atom').CompositeDisposable;

  fs = require('fs');

  Path = require('path');

  RAILS_ROOT = atom.project.getPaths()[0];

  module.exports = {
    activate: function(state) {
      return atom.commands.add('atom-workspace', "rails-open-rspec:open-rspec-file", (function(_this) {
        return function() {
          return _this.openSpec();
        };
      })(this));
    },
    openSpec: function() {
      var currentFilepath, editor, openFilePath;
      console.log("RAIL_ROOT => " + RAILS_ROOT);
      editor = atom.workspace.getActiveTextEditor();
      currentFilepath = editor.getPath();
      openFilePath = this.findFilepath(currentFilepath);
      console.log(openFilePath);
      if (fs.existsSync(openFilePath)) {
        console.log('file exists!');
        return atom.workspace.open(openFilePath, {
          split: this.direction(openFilePath)
        });
      } else if (openFilePath !== null) {
        console.log('file not exists!');
        return atom.workspace.open(openFilePath, {
          split: 'right'
        });
      }
    },
    findFilepath: function(currentFilepath) {
      var openFilePath, relativePath;
      relativePath = currentFilepath.substring(RAILS_ROOT.length);
      if (this.isSpecFile(relativePath)) {
        openFilePath = relativePath.replace(/\_spec\.rb$/, '.rb');
        openFilePath = openFilePath.replace(/^\/spec\//, "/app/");
      } else {
        openFilePath = relativePath.replace(/\.rb$/, '_spec.rb');
        openFilePath = openFilePath.replace(/^\/app\//, "/spec/");
      }
      if (relativePath === openFilePath) {
        return null;
      } else {
        return Path.join(RAILS_ROOT, openFilePath);
      }
    },
    isSpecFile: function(path) {
      return /_spec\.rb/.test(path);
    },
    direction: function(filePath) {
      if (this.isSpecFile(filePath)) {
        return 'right';
      } else {
        return 'left';
      }
    }
  };

}).call(this);
