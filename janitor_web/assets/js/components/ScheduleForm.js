import React, { Component } from 'react';
import PropTypes from 'prop-types';
import Flatpickr from 'react-flatpickr';
import 'flatpickr/dist/flatpickr.min.css';
import { makeRequest } from '../utils';

class ScheduleForm extends Component {
  static propTypes = {
    endpoint: PropTypes.string.isRequired,
    updateSchedule: PropTypes.func.isRequired,
    schedule: PropTypes.object
  };

  pickFirstDay = (days) => days.length ? days[0] : 'Monday';
  pickFirstTime = (times) => times.length ? times[0] : '23:59';
  
  convertFormFieldsToApiSpec = (form) => {
    const copy = { ...form };

    if (copy.frequency === 'daily') {
      copy.days = [];
    } else {
      copy.days = typeof copy.days === 'string' ? [copy.days] : copy.days;
    }

    copy.times = typeof copy.times === 'string' ? [copy.times] : copy.times;
    copy.preserve = Number(copy.preserve);
    delete copy.backups;

    return copy;
  };

  defaultForm = {
    db: 'mysql',
    host: 'localhost',
    port: 3306,
    username: 'root',
    password: '',
    name: '',
    preserve: 5,
    frequency: 'daily',
    days: 'Sunday',
    times: '23:59'
  };

  state = {
    dbs: ['mysql', 'postgresql'],
    frequencies: ['daily', 'weekly'],
    days: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
    databases: [],
    fetching: false,
    canFetch: true,
    isFormValid: false,
    action: this.props.schedule ? 'Update' : 'Create',
    form: this.props.schedule
      ? { ...this.props.schedule, days: this.pickFirstDay(this.props.schedule.days), times: this.pickFirstTime(this.props.schedule.times)} 
      : { ...this.defaultForm }
  };

  fetchDatabases = (e) => {
    if (e) {
      e.preventDefault();
      e.stopPropagation();
    }

    const { state: { form: { host, port, username, password, db } }, props: { endpoint } } = this;

    this.setState({ fetching: true });

    makeRequest(`${endpoint}databases`, 'post', { host, port, username, password, db })
    .then(response => response.status === 200 ? response.json(): [])
    .then(databases => this.setState({ databases, fetching: false }));
  };

  handleChange = (e) => {
    let { databases, form: { port, username } } = this.state;
    const field = e.target.name;
    const isNumeric = ['preserve'].includes(field);
    const value = isNumeric ? Number(e.target.value) : e.target.value;

    if (field === 'name' && value === 'Select a database') return;

    if (field === 'db') {
      port = value === 'mysql' ? 3306 : 5432;
      username = value === 'mysql' ? 'root' : 'postgres';
      databases = [];
    }

    const form = { ...this.state.form, port, username, [field]: value };

    this.setState({
      ...this.state,
      databases,
      form,
      isFormValid: this.validateForm(form),
      canFetch: this.isServerInfoAvailable(form)
    });
  }

  updateTime = ([date]) => {
    let minutes = date.getMinutes();
    if (minutes < 9) minutes = `0${minutes}`;

    const form = { ...this.state.form, times: `${date.getHours()}:${minutes}` };

    this.setState({
      ...this.state,
      form,
      isFormValid: this.validateForm(form)
    });
  }

  handleSubmit = (e) => {
    e.preventDefault();
    e.stopPropagation();

    const { state: { form }, props: { endpoint, updateSchedule } } = this;

    makeRequest(
      form.id ? `${endpoint}${form.id}` : endpoint, 
      form.id ? 'put' : 'post', 
      this.convertFormFieldsToApiSpec(form)
    )
      .then((response) => {
        if (Math.floor(response.status / 100) === 2) {
          this.clearForm();
          return response.json();
        }
      })
      .then(schedule => !!schedule ? updateSchedule(schedule) : null);
  };

  clearForm = () => {
    let { form } = this.state;
    
    form.name = this.defaultForm.name;
    form.preserve = this.defaultForm.preserve;
    form.frequency = this.defaultForm.frequency;
    form.days = this.defaultForm.days;
    form.times = this.defaultForm.times;

    this.setState({
      ...this.state,
      form,
      isFormValid: false,
      canFetch: false
    });
  }

  validateForm = (form) => {
    const { days, dbs, frequencies } = this.state;

    return !!form.name &&
      !!form.host &&
      !!form.port &&
      !!form.username &&
      !!form.preserve &&
      !!form.times &&
      dbs.includes(form.db) &&
      frequencies.includes(form.frequency) &&
      (form.frequency === 'weekly' ? days.includes(form.days) : true);
  }

  isServerInfoAvailable = ({ host, port, username, db }) =>
    !!host && port && this.state.dbs.includes(db) && !!username;

  componentDidMount() {
    // If this is an update, we need to fetch databases immediately
    if (this.state.form.id) this.fetchDatabases();
  }

  render() {
    const { action, days, dbs, form, frequencies, isFormValid, fetching, databases, canFetch } = this.state;
    const nameSelectClasses = `select${fetching ? ' is-loading' : ''}`;
    const fetchButtonClasses = `button is-info is-outlined${fetching ? ' is-loading' : ''}`;

    return (
      <div className="column is-one-third">
        <form onSubmit={this.handleSubmit}>
          <div className="field">
            <label className="label">Database type</label>
            <div className="select">
              <select name="db" onChange={this.handleChange} value={form.db}>
                {dbs.map(x => <option value={x} key={x}>{x}</option>)}
              </select>
            </div>
          </div>
          <div className="columns">
            <div className="column">
              <div className="field">
                <label className="label">Database host</label>
                <div className="control">
                  <input
                    className="input"
                    placeholder="Database host"
                    type="text"
                    name="host"
                    onChange={this.handleChange}
                    value={form.host}
                    required
                  />
                </div>
              </div>
            </div>
            <div className="column">
              <div className="field">
                <label className="label">Database port</label>
                <div className="control">
                  <input
                    className="input"
                    type="number"
                    name="port"
                    onChange={this.handleChange}
                    value={form.port}
                    required
                  />
                </div>
              </div>
            </div>
          </div>
          <div className="columns">
            <div className="column">
              <div className="field">
                <label className="label">Database username</label>
                <div className="control">
                  <input
                    className="input"
                    type="text"
                    name="username"
                    onChange={this.handleChange}
                    value={form.username}
                    required
                  />
                </div>
              </div>
            </div>
            <div className="column">
              <div className="field">
                <label className="label">Database password</label>
                <div className="control">
                  <input
                    className="input"
                    type="text"
                    name="password"
                    onChange={this.handleChange}
                    value={form.password}
                  />
                </div>
              </div>
            </div>
          </div>

          {
            !canFetch ? '' :
              <div className="control" style={{ marginBottom: '10px' }}>
                <button onClick={this.fetchDatabases} disabled={fetching} className={fetchButtonClasses}>
                  Fetch databases
                </button>
              </div>
          }

          <div className="columns">
            <div className="column">
              <div className="field">
                <label className="label">Database</label>
                <div className="control">
                  <div className={nameSelectClasses}>
                    <select name="name" onChange={this.handleChange} value={form.name}>
                      <option>Select a database</option>
                      {databases.map(d => <option value={d} key={d}>{d}</option>)}
                    </select>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Only show other fields if a database has been selected */
            !!form.name ?
            (
              <div>
                <div className="columns">
                  <div className="column">
                    <div className="field">
                      <label className="label">Backup frequency</label>
                      <div className="select">
                        <select name="frequency" onChange={this.handleChange} value={form.frequency}>
                          {frequencies.map(s => <option value={s} key={s}>{s}</option>)}
                        </select>
                      </div>
                    </div>
                  </div>
                  {
                    form.frequency === 'weekly' ?
                      (
                        <div className="column">
                          <div className="field">
                            <label className="label">Day</label>
                            <div className="select">
                              <select name="days" onChange={this.handleChange} value={form.days}>
                                {days.map(d => <option value={d} key={d}>{d}</option>)}
                              </select>
                            </div>
                          </div>
                        </div>
                      ) :
                      ''
                  }
                  <div className="column">
                    <div className="field">
                      <label className="label">Time</label>
                      <div className="control">
                        <Flatpickr
                          data-enable-time
                          required
                          options={{ enableTime: true, noCalendar: true, dateFormat: 'H:i' }}
                          className="input"
                          name="times"
                          value={form.times}
                          onChange={this.updateTime} />
                      </div>
                    </div>
                  </div>
                </div>

                <div className="field">
                  <label className="label">Preserve last {form.preserve} backups</label>
                  <div className="control">
                    <input
                      className="input"
                      type="number"
                      name="preserve"
                      onChange={this.handleChange}
                      value={form.preserve}
                      required
                    />
                  </div>
                </div>
                <div className="control">
                  <button disabled={!isFormValid} type="submit" className="button is-info">
                    {action} backup schedule
                  </button>
                </div>
              </div>
            ) :
            ''
          }
        </form>
      </div>
    );
  }
}

export default ScheduleForm;