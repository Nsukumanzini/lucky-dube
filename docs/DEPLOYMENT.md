# Web deployment — 21 November 2026

Production: https://lucky-dube.vercel.app/
Vercel project: lucky-dube
Project ID: prj_6xIl5R2wDn2HsA1LUy43hRBjVUHW
Team: nsukumanzinis-projects
Deployment: dpl_8GNUX8S63kHhrsyzr1JQZGr8Jabj
Status: READY

Deployed the verified Flutter release as static files using the connected Vercel API. No backend was introduced. Browser verification covered onboarding, demo login and the Grade 8 dashboard. The production address responds publicly; team preview aliases retain Vercel authentication.

GitHub creation was rejected by the integration (GraphQL createRepository and REST POST /user/repos: Resource not accessible by integration). Source and web-dist are committed locally. Intended private repository: Nsukumanzini/Lucky-Dube. GitHub push and automatic Git deployments remain pending repository creation and access. No GitHub repository was created by this session.

Vercel's currently deployed output is the contents of web-dist at deployment root. For a future Git-based deployment, vercel.json points outputDirectory to web-dist. Once a repository exists, push the source and connect it to this existing Vercel project; do not create a second project.
