import React from 'react'
import { Admin, Resource } from 'react-admin'
import { Auth } from '@moonlight-labs/core-auth-fe'
import { HomeView, CustomLayout } from '@moonlight-labs/core-config-fe'
import { Jobs } from '@moonlight-labs/core-jobs-fe'
import { useAppInit } from './useAppInit'

export const AdminApp = () => {
  const { loading: appLoading, authProvider, dataProvider } = useAppInit()

  if (appLoading) return <div>Loading...</div>
  
  return (
    <Admin
      loginPage={Auth.RA.LoginPage}
      disableTelemetry
      authProvider={authProvider}
      dataProvider={dataProvider}
      dashboard={HomeView}
      layout={CustomLayout}
    >
    <Resource
      name={Auth.Users.Name}
      icon={Auth.Users.Icon}
      list={Auth.Users.List}
      show={Auth.Users.Show}
      recordRepresentation={Auth.Users.Identifier}
    />
    <Resource
      name='Job'
      icon={Jobs.Icon}
      edit={Jobs.Edit}
      list={Jobs.List}
      recordRepresentation={Jobs.resourceRepresentation}
    />
    <Resource name='Identity' />
  </Admin>
)}