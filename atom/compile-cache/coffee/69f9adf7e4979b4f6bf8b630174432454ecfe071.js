
/*
Requires https://github.com/bbatsov/rubocop
 */

(function() {
  "use strict";
  var Beautifier, Rubocop,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Beautifier = require('./beautifier');

  module.exports = Rubocop = (function(_super) {
    __extends(Rubocop, _super);

    function Rubocop() {
      return Rubocop.__super__.constructor.apply(this, arguments);
    }

    Rubocop.prototype.name = "Rubocop";

    Rubocop.prototype.options = {
      Ruby: {
        indent_size: true
      }
    };

    Rubocop.prototype.beautify = function(text, language, options) {
      var config, configStr, tempFile, yaml;
      yaml = require("yaml-front-matter");
      config = {
        "Style/IndentationWidth": {
          "Width": options.indent_size
        }
      };
      configStr = yaml.safeDump(config);
      this.debug("rubocop", config, configStr);
      return this.run("rubocop", ["--auto-correct", tempFile = this.tempFile("temp", text)], {
        ignoreReturnCode: true
      }).then((function(_this) {
        return function() {
          return _this.readFile(tempFile);
        };
      })(this));
    };

    return Rubocop;

  })(Beautifier);

}).call(this);

//# sourceMappingURL=data:application/json;base64,ewogICJ2ZXJzaW9uIjogMywKICAiZmlsZSI6ICIiLAogICJzb3VyY2VSb290IjogIiIsCiAgInNvdXJjZXMiOiBbCiAgICAiIgogIF0sCiAgIm5hbWVzIjogW10sCiAgIm1hcHBpbmdzIjogIkFBQUE7QUFBQTs7R0FBQTtBQUFBO0FBQUE7QUFBQSxFQUlBLFlBSkEsQ0FBQTtBQUFBLE1BQUEsbUJBQUE7SUFBQTttU0FBQTs7QUFBQSxFQUtBLFVBQUEsR0FBYSxPQUFBLENBQVEsY0FBUixDQUxiLENBQUE7O0FBQUEsRUFPQSxNQUFNLENBQUMsT0FBUCxHQUF1QjtBQUNyQiw4QkFBQSxDQUFBOzs7O0tBQUE7O0FBQUEsc0JBQUEsSUFBQSxHQUFNLFNBQU4sQ0FBQTs7QUFBQSxzQkFFQSxPQUFBLEdBQVM7QUFBQSxNQUNQLElBQUEsRUFDRTtBQUFBLFFBQUEsV0FBQSxFQUFhLElBQWI7T0FGSztLQUZULENBQUE7O0FBQUEsc0JBT0EsUUFBQSxHQUFVLFNBQUMsSUFBRCxFQUFPLFFBQVAsRUFBaUIsT0FBakIsR0FBQTtBQUdSLFVBQUEsaUNBQUE7QUFBQSxNQUFBLElBQUEsR0FBTyxPQUFBLENBQVEsbUJBQVIsQ0FBUCxDQUFBO0FBQUEsTUFFQSxNQUFBLEdBQVM7QUFBQSxRQUNQLHdCQUFBLEVBQ0U7QUFBQSxVQUFBLE9BQUEsRUFBUyxPQUFPLENBQUMsV0FBakI7U0FGSztPQUZULENBQUE7QUFBQSxNQU1BLFNBQUEsR0FBWSxJQUFJLENBQUMsUUFBTCxDQUFjLE1BQWQsQ0FOWixDQUFBO0FBQUEsTUFPQSxJQUFDLENBQUEsS0FBRCxDQUFPLFNBQVAsRUFBa0IsTUFBbEIsRUFBMEIsU0FBMUIsQ0FQQSxDQUFBO2FBU0EsSUFBQyxDQUFBLEdBQUQsQ0FBSyxTQUFMLEVBQWdCLENBQ2QsZ0JBRGMsRUFHZCxRQUFBLEdBQVcsSUFBQyxDQUFBLFFBQUQsQ0FBVSxNQUFWLEVBQWtCLElBQWxCLENBSEcsQ0FBaEIsRUFJSztBQUFBLFFBQUMsZ0JBQUEsRUFBa0IsSUFBbkI7T0FKTCxDQUtFLENBQUMsSUFMSCxDQUtRLENBQUEsU0FBQSxLQUFBLEdBQUE7ZUFBQSxTQUFBLEdBQUE7aUJBRUosS0FBQyxDQUFBLFFBQUQsQ0FBVSxRQUFWLEVBRkk7UUFBQSxFQUFBO01BQUEsQ0FBQSxDQUFBLENBQUEsSUFBQSxDQUxSLEVBWlE7SUFBQSxDQVBWLENBQUE7O21CQUFBOztLQURxQyxXQVB2QyxDQUFBO0FBQUEiCn0=
//# sourceURL=/Users/deimel/.atom/packages/atom-beautify/src/beautifiers/rubocop.coffee