# TL;DR

A strategy for managing monthly releases.

## Process

[Git flow](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow) is a git-branching strategy that works well for a software product that delivers software to multiple environments including those managed by external customers.

[Github flow](https://docs.github.com/en/get-started/using-github/github-flow) is a simpler process for teams that [continuously deploy](https://github.com/resources/articles/continuous-deployment) to environments they control - like a SaaS product.

We follow a git-flow like process that stages software to a "dev" branch, and
periodically merges into a release "main" branch.  We assume that each git repository
tracks software managed by a single team that follows its own release
cycle independent of software tracked in other repositories.

We use the following terminology.

* release - a set of software features delivered to customers via 
a series of delivery artifacts (typically docker images) tagged with a string with form: `$majorVersion.$minorVersion.$patchVersion` where odd minor versions are reserved for "dev" releases
* environment - a software environment that runs the software
* tenant - a partition of the data managed by the software owned by a particular customer
* region - a geographic partitioning of an environment

### Release Management

This process is suitable for a development group with 3 to 5 teams of 5 to 10 each that wants to maintain a monthly release schedule.  For each month long sprint the product has three releases in in different stages of a deployment pipeline.

* *planning* - the release whose feature set is be planned during the sprint, for development in the next sprint
* *development* - the release under active development during the sprint that will be promoted to production at the beginning of the next sprint.  Development versions are tagged on the "dev" branch with a "dev" prefix
* *beta* - the release promoted to production at the beginning of the sprint, and deployed to environments controlled by the product team (patches can be applied without coordination with external consumers) and pre-production environments managed by customers
    - beta releases are tagged versions on the "main" branch with a "beta" prefix
    - bugs found during beta testing are merged into the main branch via "hotfix" branches
* *ga* - the release supported for production deployments tagged with a "ga" prefix - the current ga release is simply a blessed previous beta release, so that release has both a "beta" and a "ga" tag

Each release has one or more release managers.  Managing a release is a three month commitment for a release manager.  During planning, the manager works with the product stake holders to identify features to include in the release and KPI's to track with the release.  Each release is documented as a project under `Notes/Projects/$Year$Month$ProjectName` which links
to work-tracking stories via tags or some similar mechanism.

During development, the manager maintains the *dev* branch of the git repositories (see below).  She coordinates the deployment of the code to a test environment, and tracks the quality of the release through qa and automated testing.

Finally, during deployment the manager promotes the code to the git main branch (see below), then deploys the code to production, and patches bugs discovered in production if the fix cannot wait for the next release.

In summary - each release progresses through a three month time boxed pipeline: planning and design, development and test, deployment and maintenance.  A release may be tracked as a Jira story that progresses through those states.

### Feature Management

Like a release - each feature has an owner that manages its progress through a pipeline that begins with specification and design, then progresses through development, test, and deployment.  A feature may be issue-tracked as a story that progresses through those states,
and documented in the owning release project under `Notes/Projects/` (see above).

A simple feature may complete its entire pipeline in less than a month, and merge into the *dev* release under development.  A more sophisticated feature might progress through multiple months of design and review before progressing to development and a phased release. 

### Communicating with Stake Holders

To successfully move a product to a monthly release cycle the project managers must introduce the product's stake holders the new process.  Each month a release of new features and improvements is deployed to each client's staging environment for client testing before promotion to production.  Client requests for simple new features might go directly into development for the next release if resources are available, but otherwise must be prioritized against other work on the release "train".

### Weekly Core Product Meeting

At the end of each week the entire group meets for an hour to present progress over the past week and goals for the next week.  Each release manager presents for 5 to 10 minutes.  The deployment manager reports on which environments (clients) the new release has been deployed to, bugs that have been revealed in production, and patches applied.  The development manager reports which features have been accepted into the release branch, and the status of QA testing.  The planning manager reports on new features and technical debt that will be addressed in the next release, and who will manage each project.

Project managers for different clients or features also speak for 5 to 10 minutes at the weekly meeting, so the entire group has a view of the work in progress across teams.

Note that although the discussion above considers an organization that assigns a different manager to each release; an equally effective strategy might instead have a single manager per team for all releases.  For example, an organization with three teams (A, B, C) might simply make the lead for each team responsible for coordinating all the release activities (planning, development, and deployment) for her team's contribution to each release.  

Or different managers might specialize in each phase of the pipeline, so each release moves from a planning manager to a development manager to a deployment manager.


## Git flow branching scheme

### Release branches

Each git repository maintains two long lived branches - `main` and `dev` for tracking code in production and development respectively.  
The release manager approves all pull requests to the code in her release.  

When a release progresses from development to deployment, its code moves from the `dev` branch into `main`.

### Release PR Review

* does the new code allow for rollback, and concurrent deploy with last release (canary, rollback)?
* does the new code work with configuration for the previous release?
* does the new code include unit tests?
* is there a straight forward way to setup a dev-test cycle to work with the new code?
* is the code running in a qa environment?
* is there a test plan?
* has the test plan been automated and executed by QA?
* where are the results of the last test cycle?
* is there an SLO? 
* has the SLO been tested?
* have the PR's dependencies been audited for security vulnerabilities?
* has the PR been analyzed for security vulnerabilities? https://www.owasp.org/index.php/Static_Code_Analysis
* does the PR test plan include test cases to verify authn and authz are enforced?
* does the PR include documentation for users (ux workflow), developers (feature design, dev-test process), operators, and testers in a `Process/Release/Semver/Feature.md` file?
* does QA sign off after executing the test plan?
* does ops sign off on the PR?
* does the release owner sign off on the PR?
