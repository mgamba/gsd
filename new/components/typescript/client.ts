import { ApolloClient, ApolloLink, HttpLink, InMemoryCache, gql } from '@apollo/client'
import { setContext } from '@apollo/client/link/context';
import { createConsumer } from '@rails/actioncable'
import ActionCableLink from 'graphql-ruby-client/subscriptions/ActionCableLink'

const CURRENT_USER_QUERY = gql`
  query User($id: ID!) {
    User(id: $id){
      id
      email
      name
      image
      roles
    }
  }
`

export const getCookie = (cookieName: string) => {
  const cookies: { [key: string]: string } = {}
  document.cookie.split('; ').forEach((cookie) => {
    const [key, value] = cookie.split('=')
    cookies[key] = value
  })
  return cookies[cookieName] || null
}

export const decodeCookie = (cookie: string | null): any => {
  // decodes signed, json encoded rails cookies

  if (!cookie) return null

  let cookie_value = unescape(cookie.split('--')[0])
  // let cookie_payload = JSON.parse(atob(cookie_value))
  // console.log('cookie_payload', cookie_payload)
  // let decoded_stored_value = atob(cookie_payload._rails.message)
  // let stored_value = JSON.parse(decoded_stored_value)
  // return stored_value

  return JSON.parse(cookie_value)
}

const credentials: any = {
  getCurrentResource: () => {
    const resource = localStorage.getItem('currentResource')
    if (!resource) return null 

    return JSON.parse(resource)
  },
  removeCurrentResource: () => localStorage.removeItem('currentResource'),
  setCurrentResource: (r) => localStorage.setItem('currentResource', JSON.stringify(r)),
  clearAuthHeaders: () => localStorage.removeItem('authCredentials'),
  getAuthHeaders: () => {
    const headers = localStorage.getItem('authCredentials')
    if (!headers) return {}

    return JSON.parse(headers)
  },
  setAuthHeaders: (headers) => localStorage.setItem('authCredentials', JSON.stringify(headers))
}

credentials.hydrateCurrentResource = async () => {
  try {
    const { data, errors} = await client.query({
      query: CURRENT_USER_QUERY,
      variables: { id: 'me' },
      fetchPolicy: 'no-cache'
    })

    credentials.setCurrentResource(data.User)
  } catch (error) {
    console.log('error', error)
  }

  return credentials.getCurrentResource()
}

// # VITE ENV
const uri = '/graphql'

const getWSURL = () => {
  return '/cable'
}

const cable = createConsumer(getWSURL())

const hasSubscriptionOperation = ({ query: { definitions } }) => {
  return definitions.some(({ kind, operation }) => kind === 'OperationDefinition' && operation === 'subscription')
}

const httpLink = new HttpLink({
  uri
});

const link = ApolloLink.split(
  hasSubscriptionOperation,
  new ActionCableLink({ cable, channelName: 'GraphQLChannel' }),
  httpLink
)

const authLink = setContext((_, { headers }) => {
  const authCookie = getCookie('auth_cookie')

  if (authCookie) {
    const { Authorization, ...authCredentials } = decodeCookie(authCookie)
    credentials.setAuthHeaders(authCredentials)
  }

  const authCredentials = credentials.getAuthHeaders()

  return {
    headers: {
      ...headers,
      ...(authCredentials)
    }
  }
});

export { credentials }

export const client = new ApolloClient({
  uri,
  cache: new InMemoryCache(),
  link: authLink.concat(link)
})