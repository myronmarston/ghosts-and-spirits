if Radiant::Config.table_exists?
  rc = Radiant::Config
  rc['admin.title'] = 'Ghosts and Spirits administration'
  rc['admin.subtitle'] = 'Manage the site content'

  rc['defaults.page.parts'] = 'body'
  rc['defaults.page.status'] = 'published'
  rc['defaults.page.filter'] = 'Textile'
end