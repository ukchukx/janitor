import React, { Component } from 'react';
import ScheduleTable from './ScheduleTable';
import ScheduleForm from './ScheduleForm';
import Schedule from './Schedule';
import { makeRequest } from '../utils';

class SchedulePage extends Component {
  state = {
    schedules: [],
    updating: -1,
    viewing: -1,
    deleting: -1,
    endpoint: 'api/schedules/'
  };

  updateSchedule(_schedule) {
    this.fetchSchedules();

    this.setState({ updating: -1 });
  }

  deleteSchedule(index) {
    if (! confirm('Are you sure?')) return;

    let { state: { endpoint, schedules, updating, viewing } } = this;

    this.setState({ deleting: index });

    makeRequest(`${endpoint}${schedules[index].id}`, 'delete')
      .then((response) => {
        if (response.status === 204) {
          this.fetchSchedules();

          if (updating === index) updating = -1;
          if (viewing === index) viewing = -1;

          this.setState({ schedules, updating, viewing });
        }
      })
      .finally(() => this.setState({ deleting: -1 }));
  }

  selectForUpdate(updating) {
    this.setState({ updating });
  }

  view(viewing) {
    this.setState({ viewing });
  }

  fetchSchedules() {
    makeRequest(this.state.endpoint)
      .then(response => response.status === 200 ? response.json() : [])
      .then(schedules => this.setState({ schedules }));
  }

  componentDidMount() {
    this.fetchSchedules();
  }

  render() {
    const { state: { viewing, updating, schedules, deleting } } = this;

    return (
      <React.Fragment>
        <nav className="navbar is-transparent">
          <div className="navbar-brand">
            <a className="navbar-item" href="/">
              <h1 className="title">Janitor</h1>
            </a>
            <div className="navbar-burger burger" data-target="navbarMenu">
              <span></span>
              <span></span>
              <span></span>
            </div>
          </div>

          <div id="navbarMenu" className="navbar-menu">
            <div className="navbar-end">
              <div className="navbar-item">
                <a className="button" href="/signout">
                  Log out
                </a>
              </div>
            </div>
          </div>
        </nav>

        <section className="section">
          <div className="container is-fluid">
            <div className="columns">
              <ScheduleForm
                key={`f-${updating}`}
                schedule={updating === -1 ? null : schedules[updating]}
                endpoint={this.state.endpoint}
                updateSchedule={this.updateSchedule.bind(this)} />
              <ScheduleTable
                schedules={this.state.schedules}
                selectForUpdate={this.selectForUpdate.bind(this)}
                deleteSchedule={this.deleteSchedule.bind(this)}
                deletingSchedule={deleting}
                view={this.view.bind(this)} />
              {viewing === -1 ?
                '' :
                <Schedule
                  key={`s-${viewing}`}
                  endpoint={this.state.endpoint}
                  schedule={schedules[viewing]}
                  updateSchedule={this.updateSchedule.bind(this)} />
                }
            </div>
          </div>
        </section>
      </React.Fragment>
    );
  }
}

export default SchedulePage;