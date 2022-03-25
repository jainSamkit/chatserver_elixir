use Amnesia

defdatabase Database do
  
  deftable(
    User,
    [:name, :password, :auth],
    type: :ordered_set
    # index: [:name]
  )
end
