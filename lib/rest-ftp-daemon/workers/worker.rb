# Instrumented WorkerBase

module RestFtpDaemon
  class Worker < BmcDaemonLib::WorkerBase
    include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation

    # NewRelic instrumentation
    add_transaction_tracer :worker_init,       category: :task
    add_transaction_tracer :worker_after,      category: :task
    add_transaction_tracer :worker_process,    category: :task
  end
end
