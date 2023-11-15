import React from 'react'
import { Resource } from '@react-admin/ra-rbac'
import { Admin, LayoutProps, houseLightTheme } from 'react-admin'
import { Auth } from '@moonlight-labs/core-auth-fe'
import { HomeView, GroovestackLayout } from '@moonlight-labs/core-config-fe'
import { Jobs } from '@moonlight-labs/core-jobs-fe'
import { useAppInit } from './useAppInit'
import { Box } from '@mui/material'

export const AdminApp = () => {
  const { loading: appLoading, authProvider, dataProvider } = useAppInit()

  if (appLoading) return <div>Loading...</div>
  
  const CustomLayout = (props: LayoutProps) => {
    return <GroovestackLayout LayoutProps={props} AppBarProps={{userMenu: <Auth.Users.Menu />}} />
  }
  
  return (
    <Admin
      loginPage={Auth.RA.LoginPage}
      disableTelemetry
      authProvider={authProvider}
      dataProvider={dataProvider}
      dashboard={HomeView}
      layout={CustomLayout}
      // theme={houseLightTheme}
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