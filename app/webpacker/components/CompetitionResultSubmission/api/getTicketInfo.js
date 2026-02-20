import { fetchJsonOrError } from '../../../lib/requests/fetchWithAuthenticityToken';
import { apiV1Urls } from '../../../lib/requests/routes.js.erb';

const getTicketInfo = async (competitionId) => {
  const response = await fetchJsonOrError(
    apiV1Urls.competitionResultSubmission.getTicketInfo(competitionId),
  );
  return response.json;
};

export default getTicketInfo;

