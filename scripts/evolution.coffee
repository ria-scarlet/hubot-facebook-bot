# Description:
#   Spam meo
#
# Dependencies:
#
# Configuration:
#   GITHUB_REPO
#   GITHUB_BRANCH (optional)
#   GITHUB_USERNAME
#   GITHUB_PASSWORD
#   GITHUB_ORINGIN
#   CLONE_PATH (optional)
#   EVOLUTION_TOKEN
#
# Commands:
#
# Author:
#   clicia scarlet <yuyuvn@icloud.com>

nodegit = require "nodegit"
promisify = require "promisify-node"
fse = promisify require "fs-extra"
appDir = require "app-root-path"
crc = require 'crc'

module.exports = (robot) ->
  github_config = repo: process.env.GITHUB_REPO,
  branch: process.env.GITHUB_BRANCH || "master",
  username: process.env.GITHUB_USERNAME,
  password: process.env.GITHUB_PASSWORD,
  origin: process.env.GITHUB_ORINGIN
  temp_path = process.env.CLONE_PATH || "#{appDir}/tmp/ria_clone"

  robot.router.post "/hubot/github/evolution", (req, res) ->
    res.setHeader 'content-type', 'text/plain'
    data = if req.body.payload? then JSON.parse req.body.payload else req.body
    return if data.token != process.env.EVOLUTION_TOKEN

    queue = robot.brain.data.code_queue
    return res.send "Nothing to do" unless queue?
    return res.send "Coding..." if queue.locked

    action = queue.state || "run_evolution"
    robot.emit action, res

  robot.on "run_evolution", (res) ->
    queue = robot.brain.data.code_queue
    queue.locked = true

    promises = []
    for file_name, file_content of queue.files ->
      promises.push new Promise (resolve, reject) ->
        fse.writeFile path.join(temp_path, "#{file_name}"), file_content
        .end (response) ->
          resolve response

    # TODO generate random name
    # branch_name = crc.crc32("#{code_content}_#{Math.floor((Math.random()*1000))}").toString(16)
    branch_name = "abc"
    repo
    index
    oid

    fse.remove(path).then ->
      nodegit.Clone "https://github.com/#{github_config.GITHUB_REPO}.git",
        temp_path,
        fetchOpts:
          callbacks:
            certificateCheck: ->
              1
    .then (r) ->
      repo = r
      commit = repo.getBranchCommit github_config.branch
      nodegit.Branch.create repo, branch_name, commit, 1
    .then ->
      Promise.all promises
    .then ->
      repo.openIndex()
    .then (i) ->
      index = i;
      index.read 1
    .then ->
      index.addByPath fileName
    .then ->
      index.write()
    .then ->
      index.writeTree()
    .then (o) ->
      oid = o
    .then (head) ->
      repo.getCommit head
    .then (parent) ->
      author = nodegit.Signature.create "Ria Scarlet",
        "yuyuvn@icloud.com", (new Date).getTime(), 0
      committer = nodegit.Signature.create "Ria Scarlet",
        "yuyuvn@icloud.com", (new Date).getTime(), 0
      repo.createCommit "HEAD", author, committer, "Update", oid, [parent]
    .then ->
      nodegit.Remote.create(repo, "origin",
      "https://github.com/#{github_config.GITHUB_ORIGIN}.git")
    .then (remote) ->
      return remote.push ["refs/heads/#{branch_name}:refs/heads/#{branch_name}"],
        callbacks:
          credentials: ->
            return nodegit.Cred.userpassPlaintextNew github_config.userName, github_config.password
    .done ->
      delete robot.brain.data.code_queue
