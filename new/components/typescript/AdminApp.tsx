import React, { useEffect, useState } from 'react'
import { Admin, Resource, localStorageStore } from 'react-admin'
import { Jobs } from '@moonlight-labs/core-jobs-fe'
import { HomeView } from '@moonlight-labs/core-config-fe'
import { initDataProvider } from './dataProvider'
import { Auth } from '@moonlight-labs/core-auth-fe'
import { gql } from '@apollo/client'
import { client } from './client'
const store = localStorageStore()

const storeActions = {
  getCurrentResource: () => store.getItem('currentUser'),
  removeCurrentResource: () => store.removeItem('currentUser'),
  setCurrentResource: (resource: any) => store.setItem('currentUser', resource),
}

const CURRENT_USER_QUERY = gql`
  query User($id: ID!) {
    User(id: $id){
      email
      id
    }
  }
`

const hydrateCurrentUser = async () => {
  let currentUser = storeActions.getCurrentResource()

  // short circuit. current user already set
  if (currentUser) return currentUser

  // // fetch current user
  const { data, errors } = await client.query({
    query: CURRENT_USER_QUERY,
    variables: { id: 'me' }
  })
  currentUser = data.User

  storeActions.setCurrentResource(currentUser)

  return currentUser
}

const credentials = {
  clearAuthHeaders: () => {},
  setAuthHeaders: () => {},
  getCurrentResource: storeActions.getCurrentResource,
  removeCurrentResource: storeActions.removeCurrentResource,
  setCurrentResource: storeActions.setCurrentResource,
  hydrateCurrentResource: hydrateCurrentUser
}

const resource = 'Users'
const requiredRole = 'admin'

const params = {
  resource: resource,
  requiredRole: requiredRole,
  client: client,
  credentials: credentials
}


const authProvider = await Auth.Providers.Mock(params)

export const AdminApp = () => {
  const [dataProvider, setDataProvider] = useState(null)

  useEffect(() => {
    console.log('init data provider')
    initDataProvider().then((graphQlDataProvider) =>
      setDataProvider(() => graphQlDataProvider),
    )
  }, [])

  if (!dataProvider) return <div>Loading...</div>

  return (
    <Admin
      loginPage={Auth.RA.LoginPage}
      disableTelemetry
      authProvider={authProvider}
      dataProvider={dataProvider}
      dashboard={HomeView}
    >
      <Resource
        name={Auth.Users.Name}
        icon={Auth.Users.Icon}
        // edit={User.Edit}
        list={Auth.Users.List}
        show={Auth.Users.Show}
        recordRepresentation="Auth Name"
        options={{ label: 'Users (Test)' }}
      />
      <Resource
        name='Job'
        icon={Jobs.Icon}
        edit={Jobs.Edit}
        list={Jobs.List}
        recordRepresentation={Jobs.resourceRepresentation}
      />
    </Admin>
  )
}