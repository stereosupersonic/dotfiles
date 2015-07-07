(function() {
  var RailsOpenRspec;

  RailsOpenRspec = require('../lib/rails-open-rspec');

  describe("RailsOpenRspec", function() {
    var activationPromise, workspaceElement, _ref;
    _ref = [], workspaceElement = _ref[0], activationPromise = _ref[1];
    beforeEach(function() {
      workspaceElement = atom.views.getView(atom.workspace);
      return activationPromise = atom.packages.activatePackage('rails-open-rspec');
    });
    return describe("when the rails-open-rspec:toggle event is triggered", function() {
      it("hides and shows the modal panel", function() {
        expect(workspaceElement.querySelector('.rails-open-rspec')).not.toExist();
        atom.commands.dispatch(workspaceElement, 'rails-open-rspec:toggle');
        waitsForPromise(function() {
          return activationPromise;
        });
        return runs(function() {
          var railsOpenRspecElement, railsOpenRspecPanel;
          expect(workspaceElement.querySelector('.rails-open-rspec')).toExist();
          railsOpenRspecElement = workspaceElement.querySelector('.rails-open-rspec');
          expect(railsOpenRspecElement).toExist();
          railsOpenRspecPanel = atom.workspace.panelForItem(railsOpenRspecElement);
          expect(railsOpenRspecPanel.isVisible()).toBe(true);
          atom.commands.dispatch(workspaceElement, 'rails-open-rspec:toggle');
          return expect(railsOpenRspecPanel.isVisible()).toBe(false);
        });
      });
      return it("hides and shows the view", function() {
        jasmine.attachToDOM(workspaceElement);
        expect(workspaceElement.querySelector('.rails-open-rspec')).not.toExist();
        atom.commands.dispatch(workspaceElement, 'rails-open-rspec:toggle');
        waitsForPromise(function() {
          return activationPromise;
        });
        return runs(function() {
          var railsOpenRspecElement;
          railsOpenRspecElement = workspaceElement.querySelector('.rails-open-rspec');
          expect(railsOpenRspecElement).toBeVisible();
          atom.commands.dispatch(workspaceElement, 'rails-open-rspec:toggle');
          return expect(railsOpenRspecElement).not.toBeVisible();
        });
      });
    });
  });

}).call(this);
