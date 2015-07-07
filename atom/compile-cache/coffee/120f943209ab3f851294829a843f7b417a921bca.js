(function() {
  var File, RubocopAutoCorrect, fs, path, temp;

  path = require('path');

  fs = require('fs-plus');

  temp = require('temp');

  File = require('atom').File;

  RubocopAutoCorrect = require('../lib/rubocop-auto-correct');

  describe("RubocopAutoCorrect", function() {
    var activationPromise, buffer, editor, filePath, workspaceElement, _ref;
    _ref = [], workspaceElement = _ref[0], editor = _ref[1], buffer = _ref[2], filePath = _ref[3], activationPromise = _ref[4];
    beforeEach(function() {
      var directory;
      directory = temp.mkdirSync();
      atom.project.setPaths([directory]);
      workspaceElement = atom.views.getView(atom.workspace);
      activationPromise = atom.packages.activatePackage('rubocop-auto-correct');
      filePath = path.join(directory, 'example.rb');
      fs.writeFileSync(filePath, '');
      atom.config.set('rubocop-auto-correct.autoRun', false);
      atom.config.set('rubocop-auto-correct.notification', false);
      atom.config.set('rubocop-auto-correct.rubocopCommandPath', 'rubocop');
      waitsForPromise(function() {
        return atom.packages.activatePackage("language-ruby");
      });
      waitsForPromise(function() {
        return atom.workspace.open(filePath).then(function(o) {
          return editor = o;
        });
      });
      runs(function() {
        buffer = editor.getBuffer();
        return atom.commands.dispatch(workspaceElement, 'rubocop-auto-correct:current-file');
      });
      return waitsForPromise(function() {
        return activationPromise;
      });
    });
    describe("when the editor is destroyed", function() {
      beforeEach(function() {
        return editor.destroy();
      });
      return it("does not leak subscriptions", function() {
        var rubocopAutoCorrect;
        rubocopAutoCorrect = atom.packages.getActivePackage('rubocop-auto-correct').mainModule.rubocopAutoCorrect;
        expect(rubocopAutoCorrect.subscriptions.disposables.size).toBe(4);
        atom.packages.deactivatePackage('rubocop-auto-correct');
        return expect(rubocopAutoCorrect.subscriptions.disposables).toBeNull();
      });
    });
    describe("when the 'rubocop-auto-correct:current-file' command is run", function() {
      beforeEach(function() {
        return buffer.setText("{ :atom => 'A hackable text editor for the 21st Century' }\n");
      });
      describe("when correct buffer", function() {
        beforeEach(function() {
          return atom.config.set('rubocop-auto-correct.correctFile', false);
        });
        it("manually run", function() {
          var bufferChangedSpy;
          atom.commands.dispatch(workspaceElement, 'rubocop-auto-correct:current-file');
          bufferChangedSpy = jasmine.createSpy();
          buffer.onDidChange(bufferChangedSpy);
          waitsFor(function() {
            return bufferChangedSpy.callCount > 0;
          });
          return runs(function() {
            return expect(buffer.getText()).toBe("{ atom: 'A hackable text editor for the 21st Century' }\n");
          });
        });
        return it("auto run", function() {
          var bufferChangedSpy;
          atom.config.set('rubocop-auto-correct.autoRun', true);
          editor.save();
          bufferChangedSpy = jasmine.createSpy();
          buffer.onDidChange(bufferChangedSpy);
          waitsFor(function() {
            return bufferChangedSpy.callCount > 0;
          });
          return runs(function() {
            return expect(buffer.getText()).toBe("{ atom: 'A hackable text editor for the 21st Century' }\n");
          });
        });
      });
      return describe("when correct file", function() {
        beforeEach(function() {
          return atom.config.set('rubocop-auto-correct.correctFile', true);
        });
        it("manually run", function() {
          var bufferChangedSpy;
          atom.commands.dispatch(workspaceElement, 'rubocop-auto-correct:current-file');
          bufferChangedSpy = jasmine.createSpy();
          buffer.onDidChange(bufferChangedSpy);
          waitsFor(function() {
            return bufferChangedSpy.callCount > 1;
          });
          return runs(function() {
            return expect(buffer.getText()).toBe("{ atom: 'A hackable text editor for the 21st Century' }\n");
          });
        });
        return it("auto run", function() {
          var bufferChangedSpy;
          atom.config.set('rubocop-auto-correct.autoRun', true);
          editor.save();
          bufferChangedSpy = jasmine.createSpy();
          buffer.onDidChange(bufferChangedSpy);
          waitsFor(function() {
            return bufferChangedSpy.callCount > 1;
          });
          return runs(function() {
            return expect(buffer.getText()).toBe("{ atom: 'A hackable text editor for the 21st Century' }\n");
          });
        });
      });
    });
    describe("when toggle config", function() {
      beforeEach(function() {
        return this.rubocopAutoCorrect = new RubocopAutoCorrect;
      });
      it("changes auto run", function() {
        atom.config.set('rubocop-auto-correct.autoRun', false);
        this.rubocopAutoCorrect.toggleAutoRun();
        expect(atom.config.get('rubocop-auto-correct').autoRun).toBe(true);
        this.rubocopAutoCorrect.toggleAutoRun();
        return expect(atom.config.get('rubocop-auto-correct').autoRun).toBe(false);
      });
      it("changes notification", function() {
        atom.config.set('rubocop-auto-correct.notification', false);
        this.rubocopAutoCorrect.toggleNotification();
        expect(atom.config.get('rubocop-auto-correct').notification).toBe(true);
        this.rubocopAutoCorrect.toggleNotification();
        return expect(atom.config.get('rubocop-auto-correct').notification).toBe(false);
      });
      return it("changes correct method", function() {
        atom.config.set('rubocop-auto-correct.correctFile', false);
        this.rubocopAutoCorrect.toggleCorrectFile();
        expect(atom.config.get('rubocop-auto-correct').correctFile).toBe(true);
        this.rubocopAutoCorrect.toggleCorrectFile();
        return expect(atom.config.get('rubocop-auto-correct').correctFile).toBe(false);
      });
    });
    return describe("when makeTempFile", function() {
      return it("run makeTempFile", function() {
        var tempFilePath;
        this.rubocopAutoCorrect = new RubocopAutoCorrect;
        tempFilePath = this.rubocopAutoCorrect.makeTempFile("rubocop.rb");
        return expect(fs.isFileSync(tempFilePath)).toBe(true);
      });
    });
  });

}).call(this);
