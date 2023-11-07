import { ApolloClient, ApolloLink, HttpLink, InMemoryCache } from '@apollo/client'
import { setContext } from '@apollo/client/link/context';
import { createConsumer } from '@rails/actioncable'
import ActionCableLink from 'graphql-ruby-client/subscriptions/ActionCableLink'

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
  const credentials = localStorage.getItem('authCredentials');
  return {
    headers: {
      ...headers,
      ...(credentials ? JSON.parse(credentials) : {})
    }
  }
});

export const client = new ApolloClient({
  uri,
  cache: new InMemoryCache(),
  link: authLink.concat(link)
})