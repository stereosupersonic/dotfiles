(function() {
  var RubocopAutoCorrect;

  RubocopAutoCorrect = require('./rubocop-auto-correct');

  module.exports = {
    config: {
      rubocopCommandPath: {
        description: 'If command doesnot work, please input rubocop full path. example: /Users/<username>/.rbenv/shims/rubocop)',
        type: 'string',
        "default": 'rubocop'
      },
      autoRun: {
        description: 'When you save the buffer, Automatically run Rubocop auto correct, But, need to run manually once at window',
        type: 'boolean',
        "default": false
      },
      notification: {
        description: 'If you want to disable notification, Please remove the check',
        type: 'boolean',
        "default": true
      },
      correctFile: {
        description: 'When enabled, correct directly in the file (Don\'t need to save)',
        type: 'boolean',
        "default": false
      }
    },
    activate: function() {
      return this.rubocopAutoCorrect = new RubocopAutoCorrect();
    },
    deactivate: function() {
      var _ref;
      if ((_ref = this.rubocopAutoCorrect) != null) {
        _ref.destroy();
      }
      return this.rubocopAutoCorrect = null;
    }
  };

}).call(this);
