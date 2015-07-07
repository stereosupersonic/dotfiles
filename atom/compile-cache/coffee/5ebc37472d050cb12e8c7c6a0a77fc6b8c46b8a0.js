(function() {
  var BufferedProcess, CompositeDisposable, RubocopAutoCorrect, fs, path, spawnSync, temp, which, _ref;

  _ref = require('atom'), CompositeDisposable = _ref.CompositeDisposable, BufferedProcess = _ref.BufferedProcess;

  spawnSync = require('child_process').spawnSync;

  which = require('which');

  path = require('path');

  fs = require('fs-plus');

  temp = require('temp');

  module.exports = RubocopAutoCorrect = (function() {
    function RubocopAutoCorrect() {
      this.subscriptions = new CompositeDisposable;
      this.subscriptions.add(atom.workspace.observeTextEditors((function(_this) {
        return function(editor) {
          if (editor.getGrammar().scopeName.match("ruby")) {
            return _this.handleEvents(editor);
          }
        };
      })(this)));
      this.subscriptions.add(atom.commands.add('atom-workspace', {
        'rubocop-auto-correct:current-file': (function(_this) {
          return function() {
            var editor;
            if (editor = atom.workspace.getActiveTextEditor()) {
              return _this.run(editor);
            }
          };
        })(this),
        'rubocop-auto-correct:toggle-auto-run': (function(_this) {
          return function() {
            return _this.toggleAutoRun();
          };
        })(this),
        'rubocop-auto-correct:toggle-notification': (function(_this) {
          return function() {
            return _this.toggleNotification();
          };
        })(this),
        'rubocop-auto-correct:toggle-correct-file': (function(_this) {
          return function() {
            return _this.toggleCorrectFile();
          };
        })(this)
      }));
    }

    RubocopAutoCorrect.prototype.destroy = function() {
      return this.subscriptions.dispose();
    };

    RubocopAutoCorrect.prototype.handleEvents = function(editor) {
      var buffer, bufferSavedSubscription, editorDestroyedSubscription;
      buffer = editor.getBuffer();
      bufferSavedSubscription = buffer.onDidSave((function(_this) {
        return function() {
          return buffer.transact(function() {
            if (atom.config.get('rubocop-auto-correct.autoRun')) {
              return _this.run(editor);
            }
          });
        };
      })(this));
      editorDestroyedSubscription = editor.onDidDestroy(function() {
        bufferSavedSubscription.dispose();
        return editorDestroyedSubscription.dispose();
      });
      this.subscriptions.add(bufferSavedSubscription);
      return this.subscriptions.add(editorDestroyedSubscription);
    };

    RubocopAutoCorrect.prototype.toggleAutoRun = function() {
      if (atom.config.get('rubocop-auto-correct.autoRun')) {
        atom.config.set('rubocop-auto-correct.autoRun', false);
        return atom.notifications.addSuccess("Turn OFF, Auto Run");
      } else {
        atom.config.set('rubocop-auto-correct.autoRun', true);
        return atom.notifications.addSuccess("Turn ON, Auto Run");
      }
    };

    RubocopAutoCorrect.prototype.toggleNotification = function() {
      if (atom.config.get('rubocop-auto-correct.notification')) {
        atom.config.set('rubocop-auto-correct.notification', false);
        return atom.notifications.addSuccess("Turn OFF, Notification");
      } else {
        atom.config.set('rubocop-auto-correct.notification', true);
        return atom.notifications.addSuccess("Turn ON, Notification");
      }
    };

    RubocopAutoCorrect.prototype.toggleCorrectFile = function() {
      if (atom.config.get('rubocop-auto-correct.correctFile')) {
        atom.config.set('rubocop-auto-correct.correctFile', false);
        return atom.notifications.addSuccess("Correct the buffer");
      } else {
        atom.config.set('rubocop-auto-correct.correctFile', true);
        return atom.notifications.addSuccess("Correct the file");
      }
    };

    RubocopAutoCorrect.prototype.run = function(editor) {
      if (!editor.getGrammar().scopeName.match("ruby")) {
        return atom.notifications.addError("Only use source.ruby");
      }
      if (atom.config.get('rubocop-auto-correct.correctFile')) {
        if (editor.isModified()) {
          editor.save();
        }
        return this.autoCorrectFile(editor.getPath());
      } else {
        return this.autoCorrectBuffer(editor.getBuffer());
      }
    };

    RubocopAutoCorrect.prototype.autoCorrectBuffer = function(buffer) {
      var args, command, options, tempFilePath;
      command = atom.config.get('rubocop-auto-correct.rubocopCommandPath');
      tempFilePath = this.makeTempFile("rubocop.rb");
      fs.writeFileSync(tempFilePath, buffer.getText());
      args = ['-a', tempFilePath];
      options = {
        encoding: 'utf-8',
        timeout: 5000
      };
      return which(command, function(err) {
        var offenses, re, rubocop;
        if (err) {
          return atom.notifications.addFatalError("Rubocop command is not found.", {
            detail: 'When you don\'t install rubocop yet, Run `gem install rubocop` first.\n\nIf you already installed rubocop, Please check package setting at `Rubocop Command Path`.'
          });
        }
        rubocop = spawnSync(command, args, options);
        if (rubocop.stderr !== "") {
          return atom.notifications.addError(rubocop.stderr);
        }
        if (rubocop.stdout.match("corrected")) {
          buffer.setTextViaDiff(fs.readFileSync(tempFilePath, 'utf-8'));
          if (atom.config.get('rubocop-auto-correct.notification')) {
            re = /^.+?(:[0-9]+:[0-9]+:.*$)/mg;
            offenses = rubocop.stdout.match(re);
            return offenses.map(function(offense) {
              var message;
              message = offense.replace(re, buffer.getBaseName() + "$1");
              return atom.notifications.addSuccess(message);
            });
          }
        }
      });
    };

    RubocopAutoCorrect.prototype.autoCorrectFile = function(filePath) {
      var args, command, stderr, stdout;
      command = atom.config.get('rubocop-auto-correct.rubocopCommandPath');
      args = ['-a', filePath];
      stdout = function(output) {
        if (output.match("corrected")) {
          if (atom.config.get('rubocop-auto-correct.notification')) {
            return atom.notifications.addSuccess(output);
          }
        }
      };
      stderr = function(output) {
        return atom.notifications.addError(output);
      };
      return which(command, function(err) {
        var rubocop;
        if (err) {
          return atom.notifications.addFatalError("Rubocop command is not found.", {
            detail: 'When you don\'t install rubocop yet, Run `gem install rubocop` first.\n\nIf you already installed rubocop, Please check package setting at `Rubocop Command Path`.'
          });
        }
        return rubocop = new BufferedProcess({
          command: command,
          args: args,
          stdout: stdout,
          stderr: stderr
        });
      });
    };

    RubocopAutoCorrect.prototype.makeTempFile = function(filename) {
      var directory, filePath;
      directory = temp.mkdirSync();
      filePath = path.join(directory, filename);
      fs.writeFileSync(filePath, '');
      return filePath;
    };

    return RubocopAutoCorrect;

  })();

}).call(this);
