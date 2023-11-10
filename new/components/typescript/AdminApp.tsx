import React, { useEffect, useState } from 'react'
import { Admin, AuthProvider, Resource } from 'react-admin'
import { Jobs } from '@moonlight-labs/core-jobs-fe'
import { HomeView } from '@moonlight-labs/core-config-fe'
import { Auth } from '@moonlight-labs/core-auth-fe'
import { ApolloProvider } from '@apollo/client'
import { theme } from './layout/theme'
import { Box } from '@mui/material'
import { gql } from '@apollo/client'

import { client, credentials } from './client'
import { initDataProvider } from './dataProvider'
import { CustomLayout } from './layout/CustomLayout'

const QUERY_APP_CONFIG = gql`
  query {
    AppConfig
}`

export const AdminApp = () => {
  const [dataProvider, setDataProvider] = useState(null)
  const [authProvider, setAuthProvider] = useState<AuthProvider | null>()
  const [appConfig, setAppConfig] = useState()

  useEffect(() => {
    initDataProvider().then((graphQlDataProvider) =>
      setDataProvider(() => graphQlDataProvider),
    )

    Auth.RA.Providers.BaseFactory({ 
      client: client,
      credentials,
      resource: 'user',
      // requiredRole: 'admin',
    }).then(authProvider => setAuthProvider(authProvider))

    client.query({ query: QUERY_APP_CONFIG }).then((data: any) => setAppConfig(data?.data?.AppConfig))
  }, [])

  if (!(appConfig && dataProvider && authProvider)) return <div>Loading...</div>

  const AppInitHeadline = () => {
    return (
      <Box sx={{ p: 3 }}>
        <div>There are currently no registered users on your application.</div>
        <div>Be the first!</div>
      </Box>
    )
  }


  const LoginPage = (props: any) => {
    return (
      <Auth.RA.LoginPage {...props} appInit={appConfig.app_init == 0} Headline={AppInitHeadline} />
    )
  }
  
  return (
    <ApolloProvider client={client}>
      <Admin
        loginPage={LoginPage}
        disableTelemetry
        authProvider={authProvider}
        dataProvider={dataProvider}
        dashboard={HomeView}
        layout={CustomLayout}
        theme={theme}
      >
      <Resource
        name={Auth.Users.Name}
        icon={Auth.Users.Icon}
        list={Auth.Users.List}
        show={Auth.Users.Show}
      />
      <Resource
        name='Job'
        icon={Jobs.Icon}
        edit={Jobs.Edit}
        list={Jobs.List}
        recordRepresentation={Jobs.resourceRepresentation}
      />
      <Resource
        name='Identity'
        />
    </Admin>
  </ApolloProvider>
)}