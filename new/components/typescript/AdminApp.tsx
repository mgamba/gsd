import React, { useEffect, useState } from 'react'
import { Admin, AuthProvider, Resource } from 'react-admin'
import { Jobs } from '@moonlight-labs/core-jobs-fe'
import { HomeView } from '@moonlight-labs/core-config-fe'
import { Auth } from '@moonlight-labs/core-auth-fe'
import { ApolloProvider } from '@apollo/client'

import { client, credentials } from './client'
import { initDataProvider } from './dataProvider'

export const AdminApp = () => {
  const [dataProvider, setDataProvider] = useState(null)
  const [authProvider, setAuthProvider] = useState<AuthProvider | null>()

  useEffect(async () => {
    initDataProvider().then((graphQlDataProvider) =>
      setDataProvider(() => graphQlDataProvider),
    )

    Auth.RA.Providers.BaseFactory({ 
      client: client,
      credentials,
      resource: 'user',
      // requiredRole: 'admin',
    }).then(authProvider => setAuthProvider(authProvider))
  }, [])

  if (!(dataProvider && authProvider)) return <div>Loading...</div>
  
  return (
    <ApolloProvider client={client}>
      <Admin
      loginPage={Auth.RA.LoginPage}
      disableTelemetry
      authProvider={authProvider}
      dataProvider={dataProvider}
      dashboard={HomeView}
    >
        <Resource
          name='Job'
          icon={Jobs.Icon}
          edit={Jobs.Edit}
          list={Jobs.List}
          recordRepresentation={Jobs.resourceRepresentation}
        />
        <Resource name='User' />
      </Admin>
    </ApolloProvider>
  )
}