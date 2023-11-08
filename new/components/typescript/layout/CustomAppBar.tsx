import { AppBar, TitlePortal } from 'react-admin'
import { Auth } from '@moonlight-labs/core-auth-fe'

export const CustomAppBar = (props: any) => {
  return (
    <AppBar
      color="primary"
      userMenu={
        <Auth.Users.Menu {...props} />
      }
    >
      <TitlePortal />
    </AppBar>
  )
}
