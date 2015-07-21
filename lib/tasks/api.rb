namespace :api do
  task status: [:environment] do
    Worker.new.start
  end
end
