Scheduler::Application.routes.draw do

  break if ARGV.join.include? 'assets:' # this prevents triggering ActiveAdmin during precompile

  ActiveAdmin.routes(self)

  root to: "roster/sessions#new", constraints: UnauthenticatedRequestFilter
  root to: "root#index", constraints: UnauthenticatedRequestFilter::AuthenticatedRequestFilter, as: nil

  get '/health', to: 'root#health'
  get '/inactive', to: 'root#inactive', as: 'inactive_user'

  namespace :scheduler do
    root to: "home#root"
    get :on_call, controller: 'home'
    resources :shifts, only: [:index] do
      match '', via: [:put], action: :update_shifts, on: :collection
    end
    resources :shift_groups

    get 'calendar/:year/:month(/:display)',  year: /\d{4}/, 
                                  month: /(january|february|march|april|may|june|july|august|september|october|november|december)/,
                                  to: 'calendar#show',
                                  as: 'calendar'
    get 'calendar/:date', date: /\d{4}-\d{2}-\d{2}/, to: 'calendar#day', as: 'calendar_day'
    get 'calendar/:month', month: /\d{4}-\d{2}/, to: 'calendar#month'

    resources :shift_assignments do
      resource :shift_swap do
        post :confirm
      end
    end
    resources :notification_settings, only: [:show, :update] do
      get :me, on: :collection
    end
    resources :flex_schedules, only: [:index, :show, :update]
    resources :people do
      resources :shift_assignments
    end
    resources :dispatch_config, except: [:new, :create, :destroy]
  end

  namespace :roster do
    resources :chapters
    resources :people
    resource :session
    #resources :cell_carriers

    match 'salesforce/new', to: 'salesforce#new', as: :salesforce_initiation, via: [:get, :post]

    scope :openid, controller: 'open_id', path: 'openid', as: 'openid' do
      get 'user/:user_id', action: :user, as: :user
      match 'id', via: [:get, :post], action: :service
      match 'endpoint', via: [:get, :post], as: :endpoint, action: :endpoint
    end
  end

  namespace :incidents do
    root to: "home#redirect_to_chapter"
    scope ':chapter_id', as: :chapter do
      root to: "home#root"
      get :operations, to: "home#operations"
      resources :event_logs
      controller :incidents_list do
        get 'incidents', as: :incidents, action: :index
        get 'incidents/map', as: :incidents_map, action: :map
      end
      resources :incidents, except: :index do

        resource :dat, controller: :dat_incidents
        resource :notification, only: [:new, :create] do
          get :recipients
        end
        resources :event_logs
        resources :responders do
          post :status, action: :update_status, on: :member
        end
        resources :cases
        resources :attachments
        resources :responder_messages do
          post :acknowledge, on: :member
        end
        resources :responder_recruitments
        
        collection do
          get :needs_report
          get :activity
          match :link_cas, via: [:get, :post], as: :link_cas
        end
        member do
          match :mark_invalid, via: [:get, :post, :put, :patch]
          match :close, via: [:post, :put, :patch]
          match :reopen, via: [:post, :put, :patch]
        end
      end
      resources :cas_incidents, only: :index do
        resources :cases, controller: 'cas_cases' do
          get :narrative, on: :member
        end
      end
      resources :cas_link, only: [:index], controller: :cas_link do
        member do
          post :link
          post :promote
          post :ignore
        end
      end

      scope "responses", controller: :responses do
        root to: :responders, as: 'responders'
      end
      resources :report_subscription, controller: 'notification_subscriptions', notification_type: 'report'
    end

    namespace :api do
      resources :incidents, only: :index
      post :twilio_incoming, controller: :responder_messages_twilio, action: :incoming
    end

    get '*glob', to: "home#redirect_to_chapter"
  end

  namespace :partners do
    resources :partners
  end

  namespace :api do
    resources :chapters, only: [:index, :show]
    resources :people, only: [:index, :show] do
      get :me, on: :collection
    end
    resources :disasters, only: [:index, :show]
  end

  namespace :admin do
    resources :chapters do
      resources :positions
      resources :counties
      resources :shifts
    end
  end

  match 'import/dispatch', via: [:head, :post], to: 'incidents/import#import_dispatch'

  mount Connect::Engine, at: '/'

  if Rails.env.development?
    controller :mailer_debug do
      get 'debug/mailers/:action'
    end
  end
end
