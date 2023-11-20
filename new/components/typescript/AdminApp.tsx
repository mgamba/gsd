import React from 'react'
import { Admin, Resource, LayoutProps, houseLightTheme } from 'react-admin'
import { Auth } from '@groovestack/auth'
import { HomeView, GroovestackLayout } from '@groovestack/config'
import { Jobs } from '@groovestack/jobs'
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
      requireAuth
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