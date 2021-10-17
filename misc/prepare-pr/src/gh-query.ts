import { Remote } from "./remote";
import { GraphQLClient } from "graphql-request";
import gql from "graphql-tag";
import { GithubViewer } from "./__generated__/GithubViewer";
import { RepositoryBranchesAndParent } from "./__generated__/RepositoryBranchesAndParent";
import { loadConfig } from "./config";

const viewerQuery = gql`
  query GithubViewer {
    viewer {
      login
    }
  }
`;
const repoQuery = gql`
  query RepositoryBranchesAndParent($owner: String!, $repo: String!) {
    repository(owner: $owner, name: $repo) {
      url
      owner {
        login
      }
      name
      isFork
      parent {
        url
        name
        owner {
          login
        }
      }
      defaultBranchRef {
        name
        target {
          oid
        }
      }
      refs(
        first: 100
        refPrefix: "refs/heads/"
        orderBy: { field: TAG_COMMIT_DATE, direction: DESC }
      ) {
        nodes {
          name
          target {
            oid
            __typename
            ... on Commit {
              message
              pushedDate
            }
          }
        }
      }
    }
  }
`;

interface Result {
  viewer: GithubViewer;
  repos: Map<Remote, RepositoryBranchesAndParent>;
}

export async function queryGh(remotes: Remote[]): Promise<Result> {
  const config = await loadConfig();
  const githubConfig = config["github.com"];
  const graphQlClient = new GraphQLClient(githubConfig.graphQlUrl, {
    headers: {
      authorization: `Bearer ${githubConfig.token}`,
    },
  });

  const viewer = graphQlClient.request(viewerQuery);

  const queries = [viewer];

  for (const r of remotes) {
    queries.push(
      graphQlClient.request(repoQuery, { owner: r.owner, repo: r.repoName })
    );
  }

  await Promise.all(queries);

  const repoResults = new Map<Remote, RepositoryBranchesAndParent>();
  for (let i = 0; i < remotes.length; i++) {
    repoResults.set(remotes[i], await queries[i + 1]);
  }

  return { viewer: await viewer, repos: repoResults };
}
