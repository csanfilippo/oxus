# Security policy

oxus gives an MCP client the paths of files Spotlight has indexed for your user. A bug that widens what it reveals, or to whom, is a security issue.

## Supported versions

oxus is pre-release. Only the latest commit on `main`, and from `v0.1.0` on the latest release, receives security fixes.

## Reporting a vulnerability

Report privately through GitHub: open the repository's **Security** tab and choose **Report a vulnerability**. Do not open a public issue, pull request or discussion.

Include:

- the oxus commit or version, macOS version, and MCP client;
- the tool call that triggers the issue, as JSON-RPC if you have it;
- what oxus returned, and what you expected it to return.

Reports are handled by a single maintainer on a best-effort basis. Expect an acknowledgement within a week, and a fix or a decision before the issue is disclosed.

## Scope

In scope, for example:

- a result that reveals a file Spotlight should not return to your user, such as one in a location excluded under Spotlight's privacy settings;
- a result that bypasses macOS privacy protection, revealing files in `~/Downloads`, `~/Documents` or `~/Desktop` without access having been granted;
- a result that includes file contents, rather than paths;
- a `search` argument that escapes its intended meaning, such as a `name_contains` that injects Spotlight query syntax, or a `folder` that searches outside the folder it names;
- anything other than JSON-RPC written to stdout, or oxus making a network request.

Out of scope, because it is the documented behaviour (see [Privacy](README.md#privacy)):

- the MCP client, and the model provider behind it, receiving the paths of any file Spotlight has indexed for your user;
- a `spotlight_query` matching on metadata or indexed text, so that a path reveals what a file contains;
- the absence of a folder allowlist.

Report these elsewhere:

- vulnerabilities in the [MCP Swift SDK](https://github.com/modelcontextprotocol/swift-sdk) to that project;
- vulnerabilities in Spotlight or macOS privacy protection to [Apple](https://security.apple.com);
- an MCP client being prompted into calling oxus against your wishes to that client's maintainers.
