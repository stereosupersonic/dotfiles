(function() {
  var GITHUB_ACCESS_TOKEN, GITHUB_USERNAME, GitHubApi, Shell, github;

  GitHubApi = require('github');

  Shell = require('shell');

  GITHUB_ACCESS_TOKEN = process.env.GITHUB_ACCESS_TOKEN;

  GITHUB_USERNAME = process.env.GITHUB_USERNAME;

  github = new GitHubApi({
    version: '3.0.0',
    host: 'api.github.com'
  });

  module.exports = {
    activate: function() {
      return atom.commands.add('atom-workspace', 'github-utils:view-pull-request', this.viewPullRequests);
    },
    viewPullRequests: function() {
      github.authenticate({
        type: 'basic',
        username: GITHUB_USERNAME,
        password: GITHUB_ACCESS_TOKEN
      });
      return Promise.all(atom.project.getDirectories().map(atom.project.repositoryForDirectory.bind(atom.project))).then(function(repos) {
        return repos.forEach(function(repo) {
          var branch, repoName, repoOwner, _ref;
          _ref = repo.getOriginURL().match(/github\.com[:\/](.*?)(\.git)?$/)[1].split('/'), repoOwner = _ref[0], repoName = _ref[1];
          branch = repo.getShortHead();
          return github.pullRequests.getAll({
            user: repoOwner,
            repo: repoName
          }, function(err, pullRequests) {
            var url, _ref1;
            url = (_ref1 = pullRequests.filter(function(pr) {
              return pr.head.ref === branch;
            })[0]) != null ? _ref1.html_url : void 0;
            if (url != null) {
              return Shell.openExternal(url);
            }
          });
        });
      });
    }
  };

}).call(this);
