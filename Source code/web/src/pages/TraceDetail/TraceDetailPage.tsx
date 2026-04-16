import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { useParams } from 'react-router-dom';
import BlockchainBadge from '../../components/BlockchainBadge/BlockchainBadge';
import FarmingAreaMap from '../../components/Map/FarmingAreaMap';
import QRCodeGenerator from '../../components/QRCode/QRCodeGenerator';
import { traceEventApi } from '../../core/api/traceEvent.api';
import {
  borderRadius,
  colors,
  shadows,
  spacing,
  typography,
} from '../../core/theme';
import type { FullTrace, TraceEvent, VerifyResult } from '../../core/types';

const pagePanel: React.CSSProperties = {
  background: colors.surface,
  borderRadius: borderRadius.xl,
  border: `1px solid ${colors.neutral[200]}`,
  boxShadow: shadows.md,
};

const eventTypeConfig: Record<
  string,
  { label: string; color: string; soft: string }
> = {
  SEEDING: { label: 'Gieo hat', color: '#16A34A', soft: '#ECFDF3' },
  FERTILIZING: { label: 'Bon phan', color: '#CA8A04', soft: '#FEF3C7' },
  WATERING: { label: 'Tuoi nuoc', color: '#0284C7', soft: '#E0F2FE' },
  PEST_CONTROL: { label: 'Phong tru sau benh', color: '#DC2626', soft: '#FEE2E2' },
  HARVESTING: { label: 'Thu hoach', color: '#EA580C', soft: '#FFEDD5' },
  PACKAGING: { label: 'Dong goi', color: '#7C3AED', soft: '#F3E8FF' },
  SHIPPING: { label: 'Van chuyen', color: '#0891B2', soft: '#CCFBF1' },
};

const certTone: Record<
  string,
  { bg: string; text: string; border: string }
> = {
  VietGAP: { bg: '#DCFCE7', text: '#166534', border: '#86EFAC' },
  GlobalGAP: { bg: '#DBEAFE', text: '#1D4ED8', border: '#93C5FD' },
  Organic: { bg: '#FEF3C7', text: '#92400E', border: '#FCD34D' },
  HACCP: { bg: '#FCE7F3', text: '#BE185D', border: '#F9A8D4' },
  ISO22000: { bg: '#E0E7FF', text: '#4338CA', border: '#A5B4FC' },
  Other: { bg: '#F3F4F6', text: '#374151', border: '#D1D5DB' },
};

const statusLabel: Record<string, string> = {
  draft: 'Nhap',
  active: 'Dang theo doi',
  completed: 'Hoan tat',
};

const TraceDetailPage: React.FC = () => {
  const { productId } = useParams<{ productId: string }>();
  const [trace, setTrace] = useState<FullTrace | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [verifyResults, setVerifyResults] = useState<
    Record<string, VerifyResult>
  >({});
  const [verifying, setVerifying] = useState<string | null>(null);

  useEffect(() => {
    if (!productId) {
      setLoading(false);
      setError('Khong tim thay ma san pham.');
      return;
    }

    let mounted = true;
    setLoading(true);
    setError('');

    traceEventApi
      .getFullTrace(productId)
      .then((response) => {
        if (mounted) {
          setTrace(response.data);
        }
      })
      .catch((err: any) => {
        if (mounted) {
          setError(err?.message || 'Khong tim thay thong tin truy xuat');
        }
      })
      .finally(() => {
        if (mounted) {
          setLoading(false);
        }
      });

    return () => {
      mounted = false;
    };
  }, [productId]);

  const handleVerify = useCallback(async (eventId: string) => {
    setVerifying(eventId);
    try {
      const { data } = await traceEventApi.verify(eventId);
      setVerifyResults((prev) => ({ ...prev, [eventId]: data }));
    } catch {
      setVerifyResults((prev) => ({
        ...prev,
        [eventId]: { verified: false, dataHash: '', event: {} as TraceEvent },
      }));
    } finally {
      setVerifying(null);
    }
  }, []);

  const overview = useMemo(() => {
    if (!trace) {
      return null;
    }

    return {
      totalEvents: trace.events.length,
      confirmedEvents: trace.events.filter(
        (item) => item.onChainStatus === 'confirmed'
      ).length,
      certifications: trace.product.farming_area?.certifications?.length || 0,
    };
  }, [trace]);

  if (loading) {
    return (
      <div
        style={{
          ...pagePanel,
          padding: spacing[8],
          textAlign: 'center',
          minHeight: 320,
          display: 'grid',
          placeItems: 'center',
        }}
      >
        <div>
          <div style={{ fontSize: 34, marginBottom: spacing[3] }}>Dang tai...</div>
          <p style={{ margin: 0, color: colors.textSecondary }}>
            He thong dang lay du lieu truy xuat va blockchain.
          </p>
        </div>
      </div>
    );
  }

  if (error || !trace || !overview) {
    return (
      <div
        style={{
          ...pagePanel,
          padding: spacing[8],
          textAlign: 'center',
          background: '#FEF2F2',
        }}
      >
        <h2
          style={{
            margin: 0,
            marginBottom: spacing[2],
            color: '#B91C1C',
          }}
        >
          Khong tim thay
        </h2>
        <p style={{ margin: 0, color: '#991B1B' }}>
          {error || 'Khong co du lieu truy xuat cho san pham nay.'}
        </p>
      </div>
    );
  }

  const { product, events, onChain } = trace;
  const farmingArea = product.farming_area;
  const certifications = farmingArea?.certifications || [];

  return (
    <div style={{ display: 'grid', gap: spacing[6], maxWidth: 1120, margin: '0 auto' }}>
      <section
        style={{
          ...pagePanel,
          padding: spacing[8],
          background:
            'radial-gradient(circle at top right, rgba(34,197,94,0.16), transparent 28%), linear-gradient(135deg, #14532D 0%, #166534 52%, #22C55E 100%)',
          color: colors.surface,
        }}
      >
        <div style={{ display: 'flex', gap: spacing[6], flexWrap: 'wrap', alignItems: 'flex-start' }}>
          <div style={{ flex: 1, minWidth: 300 }}>
            <div
              style={{
                display: 'inline-flex',
                borderRadius: borderRadius.full,
                padding: `${spacing[2]} ${spacing[3]}`,
                background: 'rgba(255,255,255,0.16)',
                fontSize: typography.sizes.sm,
                fontWeight: typography.weights.semibold,
                marginBottom: spacing[4],
              }}
            >
              {product.type === 'Plant' ? 'Trong trot' : 'Chan nuoi'} · {product.category}
            </div>

            <h1
              style={{
                margin: 0,
                fontSize: typography.sizes['3xl'],
                fontWeight: typography.weights.bold,
                marginBottom: spacing[3],
              }}
            >
              {product.name}
            </h1>

            {product.description && (
              <p
                style={{
                  margin: 0,
                  fontSize: typography.sizes.base,
                  lineHeight: 1.75,
                  opacity: 0.94,
                  marginBottom: spacing[4],
                }}
              >
                {product.description}
              </p>
            )}

            <div
              style={{
                display: 'grid',
                gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
                gap: spacing[3],
              }}
            >
              <div>
                <div style={{ fontSize: typography.sizes.xs, opacity: 0.78 }}>
                  Xuat xu
                </div>
                <div style={{ fontWeight: typography.weights.semibold }}>
                  {product.origin}
                </div>
              </div>
              <div>
                <div style={{ fontSize: typography.sizes.xs, opacity: 0.78 }}>
                  Trang thai
                </div>
                <div style={{ fontWeight: typography.weights.semibold }}>
                  {statusLabel[product.status] || product.status}
                </div>
              </div>
              <div style={{ gridColumn: '1 / -1' }}>
                <div style={{ fontSize: typography.sizes.xs, opacity: 0.78 }}>
                  Ma truy xuat
                </div>
                <div
                  style={{
                    marginTop: spacing[1],
                    fontFamily: typography.fontFamilyMono,
                    fontSize: typography.sizes.xs,
                    background: 'rgba(0,0,0,0.18)',
                    borderRadius: borderRadius.lg,
                    padding: `${spacing[2]} ${spacing[3]}`,
                    wordBreak: 'break-all',
                  }}
                >
                  {product._id}
                </div>
              </div>
            </div>
          </div>

          <div
            style={{
              ...pagePanel,
              padding: spacing[4],
              background: colors.surface,
              minWidth: 220,
            }}
          >
            <QRCodeGenerator productId={product._id} productName={product.name} />
            <p
              style={{
                margin: `${spacing[2]} 0 0`,
                textAlign: 'center',
                color: colors.textSecondary,
                fontSize: typography.sizes.xs,
              }}
            >
              Quet de xem truy xuat tren web
            </p>
          </div>
        </div>
      </section>

      <section
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
          gap: spacing[4],
        }}
      >
        {[
          {
            label: 'Tong su kien',
            value: `${overview.totalEvents}`,
            tone: colors.primary[50],
            text: colors.primary[700],
          },
          {
            label: 'Da len blockchain',
            value: `${overview.confirmedEvents}`,
            tone: '#DBEAFE',
            text: '#1D4ED8',
          },
          {
            label: 'Chung nhan',
            value: `${overview.certifications}`,
            tone: '#FEF3C7',
            text: '#92400E',
          },
        ].map((item) => (
          <div
            key={item.label}
            style={{
              ...pagePanel,
              padding: spacing[5],
              background: item.tone,
            }}
          >
            <div
              style={{
                color: colors.textSecondary,
                fontSize: typography.sizes.xs,
                marginBottom: spacing[2],
              }}
            >
              {item.label}
            </div>
            <div
              style={{
                fontSize: typography.sizes['2xl'],
                fontWeight: typography.weights.bold,
                color: item.text,
              }}
            >
              {item.value}
            </div>
          </div>
        ))}
      </section>

      <section
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))',
          gap: spacing[5],
        }}
      >
        {farmingArea && (
          <div style={{ ...pagePanel, padding: spacing[5], display: 'grid', gap: spacing[4] }}>
            <div>
              <h2
                style={{
                  margin: 0,
                  fontSize: typography.sizes.xl,
                  fontWeight: typography.weights.bold,
                }}
              >
                Vung canh tac
              </h2>
              <p
                style={{
                  margin: `${spacing[2]} 0 0`,
                  color: colors.textSecondary,
                  fontSize: typography.sizes.sm,
                }}
              >
                Ban do, dia chi va thong tin chu so huu
              </p>
            </div>

            <div style={{ display: 'grid', gap: spacing[3] }}>
              <div>
                <div style={{ fontSize: typography.sizes.xs, color: colors.textSecondary }}>
                  Ten vung
                </div>
                <div style={{ fontWeight: typography.weights.semibold }}>
                  {farmingArea.name}
                </div>
              </div>
              <div>
                <div style={{ fontSize: typography.sizes.xs, color: colors.textSecondary }}>
                  Dia chi
                </div>
                <div style={{ fontSize: typography.sizes.sm, lineHeight: 1.7 }}>
                  {farmingArea.address}
                </div>
              </div>
              {farmingArea.area_size && (
                <div>
                  <div style={{ fontSize: typography.sizes.xs, color: colors.textSecondary }}>
                    Dien tich
                  </div>
                  <div style={{ fontWeight: typography.weights.semibold }}>
                    {farmingArea.area_size} ha
                  </div>
                </div>
              )}
              {farmingArea.owner && (
                <div>
                  <div style={{ fontSize: typography.sizes.xs, color: colors.textSecondary }}>
                    Chu so huu
                  </div>
                  <div style={{ fontWeight: typography.weights.semibold }}>
                    {farmingArea.owner.first_name} {farmingArea.owner.last_name}
                  </div>
                </div>
              )}
            </div>

            <FarmingAreaMap
              coordinates={farmingArea.coordinates}
              address={farmingArea.address}
              title="Ban do vung canh tac"
              height={240}
            />
          </div>
        )}

        {certifications.length > 0 && (
          <div style={{ ...pagePanel, padding: spacing[5], display: 'grid', gap: spacing[4] }}>
            <div>
              <h2
                style={{
                  margin: 0,
                  fontSize: typography.sizes.xl,
                  fontWeight: typography.weights.bold,
                }}
              >
                Chung nhan chat luong
              </h2>
              <p
                style={{
                  margin: `${spacing[2]} 0 0`,
                  color: colors.textSecondary,
                  fontSize: typography.sizes.sm,
                }}
              >
                Danh sach chung nhan dang gan voi vung trong
              </p>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: spacing[3] }}>
              {certifications.map((certification) => {
                const tone = certTone[certification.type] || certTone.Other;
                const valid = certification.status === 'valid';
                return (
                  <div
                    key={certification._id}
                    style={{
                      padding: spacing[4],
                      borderRadius: borderRadius.lg,
                      background: valid ? tone.bg : colors.neutral[50],
                      border: `1px solid ${valid ? tone.border : colors.neutral[200]}`,
                    }}
                  >
                    <div
                      style={{
                        display: 'flex',
                        justifyContent: 'space-between',
                        gap: spacing[3],
                        alignItems: 'flex-start',
                        marginBottom: spacing[2],
                      }}
                    >
                      <div style={{ fontWeight: typography.weights.semibold, color: tone.text }}>
                        {certification.name}
                      </div>
                      <span
                        style={{
                          borderRadius: borderRadius.md,
                          padding: `${spacing[1]} ${spacing[2]}`,
                          fontSize: typography.sizes.xs,
                          fontWeight: typography.weights.semibold,
                          background: valid ? '#DCFCE7' : '#FEE2E2',
                          color: valid ? '#166534' : '#B91C1C',
                        }}
                      >
                        {valid ? 'Con hieu luc' : 'Het han'}
                      </span>
                    </div>
                    <div style={{ fontSize: typography.sizes.xs, color: colors.textSecondary }}>
                      Loai: {certification.type}
                    </div>
                    <div style={{ fontSize: typography.sizes.xs, color: colors.textSecondary }}>
                      So chung nhan: {certification.certificate_number}
                    </div>
                    <div style={{ fontSize: typography.sizes.xs, color: colors.textSecondary }}>
                      Cap boi: {certification.issuing_authority}
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        )}

        {onChain && (
          <div style={{ ...pagePanel, padding: spacing[5], display: 'grid', gap: spacing[4] }}>
            <div>
              <h2
                style={{
                  margin: 0,
                  fontSize: typography.sizes.xl,
                  fontWeight: typography.weights.bold,
                }}
              >
                Lien ket blockchain
              </h2>
              <p
                style={{
                  margin: `${spacing[2]} 0 0`,
                  color: colors.textSecondary,
                  fontSize: typography.sizes.sm,
                }}
              >
                Chu so huu batch va so luong hanh dong da ghi
              </p>
            </div>

            <div
              style={{
                padding: spacing[4],
                borderRadius: borderRadius.lg,
                background: '#EFF6FF',
              }}
            >
              <div style={{ fontSize: typography.sizes.xs, color: colors.textSecondary }}>
                Owner address
              </div>
              <div
                style={{
                  marginTop: spacing[1],
                  fontFamily: typography.fontFamilyMono,
                  fontSize: typography.sizes.xs,
                  color: '#1D4ED8',
                  wordBreak: 'break-all',
                }}
              >
                {onChain.owner}
              </div>
            </div>

            <div
              style={{
                padding: spacing[4],
                borderRadius: borderRadius.lg,
                background: '#DCFCE7',
                color: '#166534',
              }}
            >
              <div style={{ fontWeight: typography.weights.bold }}>
                {onChain.actions.length} su kien da duoc ghi
              </div>
              <div style={{ fontSize: typography.sizes.sm, marginTop: spacing[1] }}>
                Du lieu da co dau vet tren blockchain va co the doi chieu.
              </div>
            </div>
          </div>
        )}
      </section>

      <section style={{ ...pagePanel, padding: spacing[6], display: 'grid', gap: spacing[5] }}>
        <div>
          <h2
            style={{
              margin: 0,
              fontSize: typography.sizes['2xl'],
              fontWeight: typography.weights.bold,
            }}
          >
            Lich su truy xuat
          </h2>
          <p
            style={{
              margin: `${spacing[2]} 0 0`,
              color: colors.textSecondary,
              fontSize: typography.sizes.sm,
            }}
          >
            Toan bo cac su kien da duoc ghi nhan cho lo nong san nay
          </p>
        </div>

        {events.length === 0 ? (
          <div
            style={{
              textAlign: 'center',
              color: colors.textSecondary,
              padding: spacing[8],
            }}
          >
            Chua co su kien nao duoc ghi nhan.
          </div>
        ) : (
          <div style={{ display: 'grid', gap: spacing[4] }}>
            {events.map((event, index) => {
              const config = eventTypeConfig[event.eventType] || {
                label: event.eventType,
                color: colors.neutral[500],
                soft: colors.neutral[100],
              };
              const result = verifyResults[event._id];

              return (
                <article
                  key={event._id}
                  style={{
                    display: 'grid',
                    gridTemplateColumns: '52px 1fr',
                    gap: spacing[4],
                    position: 'relative',
                  }}
                >
                  <div style={{ position: 'relative' }}>
                    <div
                      style={{
                        width: 44,
                        height: 44,
                        borderRadius: borderRadius.lg,
                        background: config.soft,
                        border: `2px solid ${config.color}`,
                        color: config.color,
                        display: 'grid',
                        placeItems: 'center',
                        fontWeight: typography.weights.bold,
                      }}
                    >
                      {index + 1}
                    </div>
                    {index < events.length - 1 && (
                      <div
                        style={{
                          position: 'absolute',
                          left: 21,
                          top: 48,
                          width: 2,
                          bottom: -spacing[4],
                          background: colors.neutral[200],
                        }}
                      />
                    )}
                  </div>

                  <div
                    style={{
                      borderRadius: borderRadius.xl,
                      background: colors.neutral[50],
                      border: `1px solid ${colors.neutral[200]}`,
                      padding: spacing[5],
                    }}
                  >
                    <div
                      style={{
                        display: 'flex',
                        justifyContent: 'space-between',
                        gap: spacing[3],
                        alignItems: 'flex-start',
                        flexWrap: 'wrap',
                        marginBottom: spacing[3],
                      }}
                    >
                      <div>
                        <div
                          style={{
                            display: 'inline-flex',
                            borderRadius: borderRadius.full,
                            padding: `${spacing[1]} ${spacing[3]}`,
                            background: config.soft,
                            color: config.color,
                            fontSize: typography.sizes.xs,
                            fontWeight: typography.weights.semibold,
                            marginBottom: spacing[2],
                          }}
                        >
                          {config.label}
                        </div>
                        <div
                          style={{
                            fontSize: typography.sizes.sm,
                            color: colors.textSecondary,
                          }}
                        >
                          {new Date(event.createdAt).toLocaleString('vi-VN')}
                        </div>
                      </div>

                      <BlockchainBadge
                        status={event.onChainStatus}
                        txHash={event.txHash}
                      />
                    </div>

                    <p
                      style={{
                        margin: 0,
                        color: colors.textPrimary,
                        lineHeight: 1.75,
                        marginBottom: spacing[3],
                      }}
                    >
                      {event.description}
                    </p>

                    {event.details && Object.keys(event.details).length > 0 && (
                      <div
                        style={{
                          padding: spacing[4],
                          borderRadius: borderRadius.lg,
                          background: colors.surface,
                          border: `1px solid ${colors.neutral[200]}`,
                          marginBottom: spacing[3],
                        }}
                      >
                        <div
                          style={{
                            fontSize: typography.sizes.xs,
                            color: colors.textSecondary,
                            marginBottom: spacing[2],
                          }}
                        >
                          Chi tiet ky thuat
                        </div>
                        <pre
                          style={{
                            margin: 0,
                            whiteSpace: 'pre-wrap',
                            wordBreak: 'break-word',
                            fontSize: typography.sizes.xs,
                            color: colors.textPrimary,
                            fontFamily: typography.fontFamilyMono,
                            lineHeight: 1.75,
                          }}
                        >
                          {JSON.stringify(event.details, null, 2)}
                        </pre>
                      </div>
                    )}

                    <div style={{ display: 'flex', gap: spacing[3], flexWrap: 'wrap' }}>
                      {event.onChainStatus === 'confirmed' && (
                        <button
                          type="button"
                          onClick={() => handleVerify(event._id)}
                          disabled={verifying === event._id}
                          style={{
                            border: `1px solid ${colors.primary[300]}`,
                            borderRadius: borderRadius.lg,
                            padding: `${spacing[2]} ${spacing[3]}`,
                            background: colors.primary[50],
                            color: colors.primary[700],
                            fontWeight: typography.weights.semibold,
                            cursor:
                              verifying === event._id ? 'not-allowed' : 'pointer',
                          }}
                        >
                          {verifying === event._id
                            ? 'Dang kiem tra...'
                            : 'Xac minh blockchain'}
                        </button>
                      )}

                      {result && (
                        <div
                          style={{
                            borderRadius: borderRadius.lg,
                            padding: `${spacing[2]} ${spacing[3]}`,
                            background: result.verified ? '#DCFCE7' : '#FEE2E2',
                            color: result.verified ? '#166534' : '#B91C1C',
                            fontSize: typography.sizes.sm,
                            fontWeight: typography.weights.semibold,
                          }}
                        >
                          {result.verified
                            ? 'Du lieu khop voi blockchain'
                            : 'Du lieu khong khop voi blockchain'}
                        </div>
                      )}
                    </div>

                    {event.dataHash && (
                      <div
                        style={{
                          marginTop: spacing[3],
                          padding: `${spacing[2]} ${spacing[3]}`,
                          borderRadius: borderRadius.lg,
                          background: colors.surface,
                          border: `1px solid ${colors.neutral[200]}`,
                          fontSize: typography.sizes.xs,
                          color: colors.textSecondary,
                        }}
                      >
                        <span>Hash: </span>
                        <span
                          style={{
                            fontFamily: typography.fontFamilyMono,
                            color: colors.neutral[500],
                            wordBreak: 'break-all',
                          }}
                        >
                          {event.dataHash}
                        </span>
                      </div>
                    )}
                  </div>
                </article>
              );
            })}
          </div>
        )}
      </section>
    </div>
  );
};

export default TraceDetailPage;
