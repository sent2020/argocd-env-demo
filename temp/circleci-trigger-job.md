# circleci

* <https://circleci.com/docs/api/#trigger-a-new-job>

```bash
curl -X POST --header "Content-Type: application/json" -d '{
  "tag": "v0.1", // optional
  "parallel": 2, //optional, default null
  "build_parameters": { // optional
    "RUN_EXTRA_TESTS": "true"
  }
}

https://circleci.com/api/v1.1/project/:vcs-type/:username/:project?circle-token=:token

```
