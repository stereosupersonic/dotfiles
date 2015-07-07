(function() {
  var RailsOpenRspecView;

  module.exports = RailsOpenRspecView = (function() {
    function RailsOpenRspecView(serializedState) {
      var message;
      this.element = document.createElement('div');
      this.element.classList.add('rails-open-rspec');
      message = document.createElement('div');
      message.textContent = "The RailsOpenRspec package is Alive! It's ALIVE!";
      message.classList.add('message');
      this.element.appendChild(message);
    }

    RailsOpenRspecView.prototype.serialize = function() {};

    RailsOpenRspecView.prototype.destroy = function() {
      return this.element.remove();
    };

    RailsOpenRspecView.prototype.getElement = function() {
      return this.element;
    };

    return RailsOpenRspecView;

  })();

}).call(this);
